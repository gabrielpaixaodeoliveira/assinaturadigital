﻿using Lacuna.Pki;
using Lacuna.Pki.Pades;
using System;
using System.IO;
using System.Web;
using WebForms.Classes;
using System.Web.UI;
using Lacuna.Pki.Stores;
using System.Collections.Generic;
using System.Linq;

namespace WebForms {
	public partial class Assinatura : System.Web.UI.Page {

		public string SignatureFile { get; private set; }
		public PKCertificate Certificate { get; private set; }

		// We'll store the uploaded file path in a session variable
		private const string UploadedFileSessionKey = "UploadedFile";

		protected void Page_Load(object sender, EventArgs e) {
			if (!IsPostBack) {
				// Initialize panel visibility
				fileUploadPanel.Visible = true;
				signaturePanel.Visible = false;
				
				// Clear any previous file selection
				fileUpload.Attributes.Add("accept", ".pdf");
			}
		}

		protected void fileUpload_FileUpload(object sender, EventArgs e) {
			if (fileUpload.HasFile) {
				try {
					// Get the uploaded file
					HttpPostedFile uploadedFile = fileUpload.PostedFile;

					// Verify if it's a PDF file
					if (!uploadedFile.ContentType.Equals("application/pdf", StringComparison.OrdinalIgnoreCase)) {
						ModelState.AddModelError("", "Por favor, selecione apenas arquivos PDF.");
						return;
					}

					// Read the file content
					byte[] fileContent;
					using (var memoryStream = new MemoryStream()) {
						uploadedFile.InputStream.CopyTo(memoryStream);
						fileContent = memoryStream.ToArray();
					}

					// Store the file content in the session
					Session["PdfToSign"] = fileContent;
					Session["UploadedFile"] = fileContent;
					Session["FileName"] = uploadedFile.FileName;

					// Update the UI to show the file is ready for signing
					fileUploadPanel.Visible = false;
					signaturePanel.Visible = true;
					fileNameLabel.Text = uploadedFile.FileName;
				}
				catch (Exception ex) {
					// Log the error
					System.Diagnostics.Debug.WriteLine($"Error uploading file: {ex.Message}");
					ModelState.AddModelError("", "Erro ao processar o arquivo. Por favor, tente novamente.");
				}
			} else {
				ModelState.AddModelError("", "Por favor, selecione um arquivo PDF para assinar.");
			}
		}

		protected void SignButton_Click(object sender, EventArgs e) {
			if (!fileUpload.HasFile) {
				ModelState.AddModelError("", "Por favor, selecione um arquivo PDF para assinar.");
				return;
			}

			if (!fileUpload.FileName.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)) {
				ModelState.AddModelError("", "Por favor, selecione apenas arquivos PDF.");
				return;
			}

			// Store the file in session for later use
			Session["UploadedFile"] = fileUpload.FileBytes;
			Session["FileName"] = fileUpload.FileName;

			// Continue with the signature process
			SubmitCertificateButton_Click(sender, e);
		}

		protected void SubmitCertificateButton_Click(object sender, EventArgs e) {
			byte[] toSignBytes, transferData;
			SignatureAlgorithm signatureAlg;

			try {
				// Get the file from session
				byte[] fileBytes = Session["UploadedFile"] as byte[];
				if (fileBytes == null) {
					ModelState.AddModelError("", "Erro ao processar o arquivo. Por favor, tente novamente.");
					return;
				}

				// Validate file size (max 10MB)
				if (fileBytes.Length > 10 * 1024 * 1024) {
					ModelState.AddModelError("", "O arquivo é muito grande. O tamanho máximo permitido é 10MB.");
					return;
				}

				// Decode the user's certificate.
				var cert = PKCertificate.Decode(Convert.FromBase64String(CertificateField.Value));

				// Instantiate a PadesSigner class.
				var padesSigner = new PadesSigner();

				// Set the PDF to sign from the uploaded file
				try {
					padesSigner.SetPdfToSign(fileBytes);
				}
				catch (Exception ex) {
					ModelState.AddModelError("", "Erro ao processar o arquivo PDF: " + ex.Message);
					return;
				}

				// Set the signer certificate.
				padesSigner.SetSigningCertificate(cert);

				// Set the signature policy.
				padesSigner.SetPolicy(getSignaturePolicy());

				// Set the signature's visual representation options (optional).
				padesSigner.SetVisualRepresentation(getVisualRepresentation(cert));

				// Generate the "to-sign-bytes". This method also yields the signature algorithm that must
				// be used on the client-side, based on the signature policy, as well as the "transfer data",
				// a byte-array that will be needed on the next step.
				toSignBytes = padesSigner.GetToSignBytes(out signatureAlg, out transferData);

			}
			catch (ValidationException ex) {
				// Some of the operations above may throw a ValidationException, for instance if the certificate
				// encoding cannot be read or if the certificate is expired. 
				ex.ValidationResults.Errors.ForEach(ve => ModelState.AddModelError("", ve.ToString()));
				return;
			}
			catch (Exception ex) {
				ModelState.AddModelError("", "Erro ao processar o arquivo: " + ex.Message);
				return;
			}

			// The "transfer data" for PDF signatures can be as large as the original PDF itself. Therefore, we
			// mustn't use a hidden field on the page to store it. Here we're using our storage mock
			// (see file Classes\Storage.cs) to simulate storing the transfer data on a database and saving on a
			// hidden field on the page only the ID that can be used later to retrieve it. Another option would
			// be to store the transfer data on the Session dictionary.
			TransferDataFileIdField.Value = Storage.StoreFile(transferData);

			// Send to the javascript the "to sign hash" of the document (digest of the "to-sign-bytes") and the
			// digest algorithm that must be used on the signature algorithm computation.
			ToSignHashField.Value = Convert.ToBase64String(signatureAlg.DigestAlgorithm.ComputeHash(toSignBytes));
			DigestAlgorithmField.Value = signatureAlg.DigestAlgorithm.Oid;
		}

		protected void SubmitSignatureButton_Click(object sender, EventArgs e) {

			byte[] signatureContent;

			try {

				// Retrieve the "transfer data" stored on the initial step (see method startNextSignature()).
				var transferData = Storage.GetFile(TransferDataFileIdField.Value);

				// We won't be needing the "transfer data" anymore, so we delete it.
				Storage.DeleteFile(TransferDataFileIdField.Value);

				// Instantiate a PadesSigner class.
				var padesSigner = new PadesSigner();

				// Set the signature policy, exactly like in the Start method.
				padesSigner.SetPolicy(getSignaturePolicy());

				// Set the signature computed on the client-side, along with the "transfer data".
				padesSigner.SetPreComputedSignature(Convert.FromBase64String(SignatureField.Value), transferData);

				// Call ComputeSignature(), which does all the work, including validation of the signer's
				// certificate and of the resulting signature.
				padesSigner.ComputeSignature();

				// Get the signed PDF as an array of bytes.
				signatureContent = padesSigner.GetPadesSignature();

			}
			catch (ValidationException ex) {
				// Some of the operations above may throw a ValidationException, for instance if the certificate
				// is revoked.
				ex.ValidationResults.Errors.ForEach(ve => ModelState.AddModelError("", ve.ToString()));
				CertificateField.Value = "";
				ToSignHashField.Value = "";
				return;
			}

			// Pass the following fields to be used on PadesSignatureInfo page:
			// - The signature file will be stored on the folder "App_Data/". Its name will be passed by
			//   SignatureFile field.
			// - The user's certificate
			this.SignatureFile = Storage.StoreFile(signatureContent, ".pdf");
			this.Certificate = PKCertificate.Decode(Convert.FromBase64String(CertificateField.Value));

			Server.Transfer("InformacoesDeAssinatura.aspx");
		}

		/// <summary>
		/// This method defines the signature policy that will be used on the signature.
		/// </summary>
		private IPadesPolicyMapper getSignaturePolicy() {
			return PadesPoliciesForGeneration.GetPadesBasic(Util.GetTrustArbitrator());
		}

		// This method defines the visual representation for each signature. For more information, see:
		// http://pki.lacunasoftware.com/Help/html/98095ec7-2742-4d1f-9709-681c684eb13b.htm
		private PadesVisualRepresentation2 getVisualRepresentation(PKCertificate cert) {

			var visualRepresentation = new PadesVisualRepresentation2() {

				// Text of the visual representation.
				Text = new PadesVisualText() {

					// used to compose the message.
					CustomText = String.Format("Assinado digitalmente por {0}", cert.SubjectName.CommonName),

					// Specify that the signing time should also be rendered.
					IncludeSigningTime = true,

					// Optionally set the horizontal alignment of the text ('Left' or 'Right'), if not set the
					// default is Left.
					HorizontalAlign = PadesTextHorizontalAlign.Left,

					// Optionally set the container within the signature rectangle on which to place the text. By
					// default, the text can occupy the entire rectangle (how much of the rectangle the text will
					// actually fill depends on the length and font size). Below, we specify that the text should
					// respect a right margin of 1.5 cm.
					Container = new PadesVisualRectangle() {
						Left = 0.2,
						Top = 0.2,
						Right = 0.2,
						Bottom = 0.2
					}
				},
				// Background image of the visual representation.
				Image = new PadesVisualImage() {

					// We'll use as background the image in Content/PdfStamp.png.
					Content = Storage.GetPdfStampContent(),
					// Align the image to the right.
					HorizontalAlign = PadesHorizontalAlign.Right
				}
			};

			// Position of the visual represention. We get the footnote position preset and customize it.
			var visualPositioning = PadesVisualAutoPositioning.GetFootnote();
			visualPositioning.Container.Height = 4.94;
			visualPositioning.SignatureRectangleSize.Width = 8.0;
			visualPositioning.SignatureRectangleSize.Height = 4.94;
			visualRepresentation.Position = visualPositioning;

			return visualRepresentation;
		}
	}
}
