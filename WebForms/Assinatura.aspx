<%@ Page Title="Assinatura" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Assinatura.aspx.cs" Inherits="WebForms.Assinatura" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

	<h2>Assinatura de documentos</h2>

	<asp:Panel ID="fileUploadPanel" runat="server" CssClass="form-group">
		<label for="fileUpload">Selecione o arquivo para assinar</label>
		<asp:FileUpload ID="fileUpload" runat="server" CssClass="form-control" accept=".pdf" onchange="uploadFile()" />
		<asp:Button ID="UploadButton" runat="server" Text="Enviar" OnClick="fileUpload_FileUpload" CssClass="btn btn-primary" Style="display: none;" />
	</asp:Panel>

	<asp:Panel ID="signaturePanel" runat="server">
		<div class="form-group">
			<asp:Label ID="fileNameLabel" runat="server" CssClass="form-control-static" />
		</div>

		<%-- 
			Render a select (combo box) to list the user's certificates. For now it will be empty, we'll populate
			it later on (see signature-forms.js).
		--%>
		<div class="form-group">
			<label for="certificateSelect">Selecione um certificado</label>
			<select id="certificateSelect" class="form-control"></select>
		</div>

		<%--
			Action buttons. Notice that both buttons have a OnClientClick attribute, which calls the client-side
			javascript functions "sign" and "refresh" below. Both functions return false, which prevents the
			postback.
		--%>
		<asp:Button ID="SignButton" runat="server" class="btn btn-primary" Text="Assinar Arquivo" OnClientClick="return sign();" />
		<asp:Button ID="RefreshButton" runat="server" class="btn btn-default" Text="Atualizar Certificados" OnClientClick="return refresh();" />
	</asp:Panel>

	<%--
		UpdatePanel used to refresh only this part of the page. This is used to send the selected
		certificate's encoding to the code-behind and receiving back the parameters for the signature
		algorithm computation.
	--%>
	<asp:UpdatePanel runat="server">
		<ContentTemplate>
			<asp:ValidationSummary runat="server" CssClass="text-danger" />

			<%-- Hidden fields used to pass data from the code-behind to the javascript and vice-versa. --%>
			<asp:HiddenField runat="server" ID="CertificateField" />
			<asp:HiddenField runat="server" ID="ToSignHashField" />
			<asp:HiddenField runat="server" ID="DigestAlgorithmField" />
			<asp:HiddenField runat="server" ID="SignatureField" />

			<%--
				Hidden fields used by the code-behind to save state between signature steps. These could be
				alternatively stored on server-side session, since we don't need their values on the
				javascript.
			--%>
			<asp:HiddenField runat="server" ID="TransferDataFileIdField" />

			<%--
				Hidden button whose click event is fired by the "signature form" javascript upon acquiring
				the selected certificate's encoding. Notice that we cannot use Visible="False" otherwise
				ASP.NET will omit the button altogether from the rendered page, making it impossible to
				programatically "click" it. Notice also that this button is inside the UpdatePanel,
				triggerring only a partial postback.
			--%>
			<asp:Button ID="SubmitCertificateButton" runat="server" OnClick="SubmitCertificateButton_Click" Style="display: none;" />
		</ContentTemplate>
	</asp:UpdatePanel>

	<%--
		Hidden button whose click event is fired by the "signature form" javascript upon completion of the
		signature of the "to sign hash". Notice that we cannot use Visible="False" otherwise ASP.NET will
		omit the button altogether from the rendered page, making it impossible to programatically "click"
		it. Notice also that this button is out of the UpdatePanel, triggering a complete postback.
	--%>
	<asp:Button ID="SubmitSignatureButton" runat="server" OnClick="SubmitSignatureButton_Click" Style="display: none;" />

	<script>

		function pageLoad() {
			signatureForm.pageLoad({
				certificateSelect: $('#certificateSelect'),
				submitCertificateButton: $('#<%= SubmitCertificateButton.ClientID %>'),
				submitSignatureButton: $('#<%= SubmitSignatureButton.ClientID %>'),
				certificateField: $('#<%= CertificateField.ClientID %>'),
				toSignHashField: $('#<%= ToSignHashField.ClientID %>'),
				digestAlgorithmField: $('#<%= DigestAlgorithmField.ClientID %>'),
				signatureField: $('#<%= SignatureField.ClientID %>')
			});
		};

		function uploadFile() {
			// Trigger the hidden upload button click
			$('#<%= UploadButton.ClientID %>').click();
		}

		function sign() {
			signatureForm.startSignature();
			return false; // Prevent postback.
		}

		function refresh() {
			signatureForm.refresh();
			return false; // Prevent postback.
		}
	</script>

</asp:Content>
