﻿// ----------------------------------------------------------------------------------------------------------
// This file contains logic for calling the Web PKI component to sign a batch of documents. It is only an
// example, feel free to alter it to meet your application's needs.
// ----------------------------------------------------------------------------------------------------------
var batchSignatureForm = (function () {

	// Auxiliary global variables.
	var formElements = {};
	var docCount = -1;
	var selectedCertThumbprint = null;
	var pki = null;

	// ------------------------------------------------------------------------------------------------------
	// Function called by a inline javascript on forms informing the number of documents in the batch.
	// ------------------------------------------------------------------------------------------------------
	function setDocumentCount(count) {
		docCount = count;
	}

	// ------------------------------------------------------------------------------------------------------
	// Function called once the page is loaded or once the update panel with the hidden fields used to pass
	// data to and from the code-behind is updated.
	// ------------------------------------------------------------------------------------------------------
	function pageLoad(fe) {

		// We update our references to the form elements everytime this function is called, since the
		// elements change when the UpdatePanel is updated.
		formElements = fe;

		if (pki === null) {
			// If the Web PKI component is not initialized that means this is the initial load of the page
			// (not a refresh of the update panel). Therefore, we initialize the Web PKI component and list
			// the user's certificates.
			initPki();
		} else if (formElements.toSignHashField.val() !== '(end)') {
			// If the Web PKI is already initialized, this is a refresh of the update panel. If the hidden
			// field "toSignHash" was filled by the code-behind with any value except "(end)", we go ahead
			// and sign the current document.
			sign();
		} else {
			// If the hidden field "toSignHash" is filled with the value "(end)", it means that the last
			// document in the batch was processed. We simply unblock the UI and return.
			$.unblockUI();
		}
	}

	// ------------------------------------------------------------------------------------------------------
	// Function that initializes the Web PKI component, called on the first load of the page.
	// ------------------------------------------------------------------------------------------------------
	function initPki() {

		// Block the UI while we get things ready.
		$.blockUI({ message: 'Initializing ...' });

		// Create an instance of the LacunaWebPKI object.
		pki = new LacunaWebPKI();

		// Call the init() method on the LacunaWebPKI object, passing a callback for when the component is
		// ready to be used and another to be called when an error occurrs on any of the subsequent
		// operations. For more information, see:
		// https://docs.lacunasoftware.com/en-us/articles/web-pki/get-started.html#coding-the-first-lines
		// http://webpki.lacunasoftware.com/Help/classes/LacunaWebPKI.html#method_init
		pki.init({
			ready: loadCertificates,    // As soon as the component is ready we'll load the certificates.
			defaultError: onWebPkiError // Generic error callback defined below.
		});
	}

	// ------------------------------------------------------------------------------------------------------
	// Function called when the user clicks the "Refresh" button.
	// ------------------------------------------------------------------------------------------------------
	function refresh() {
		// Block the UI while we load the certificates.
		$.blockUI();
		// Invoke the loading of the certificates.
		loadCertificates();
	}

	// ------------------------------------------------------------------------------------------------------
	// Function that loads the certificates, either on startup or when the user clicks the "Refresh" button.
	// At this point, the UI is already blocked.
	// ------------------------------------------------------------------------------------------------------
	function loadCertificates() {

		// Call the listCertificates() method to list the user's certificates. For more information see:
		// http://webpki.lacunasoftware.com/Help/classes/LacunaWebPKI.html#method_listCertificates
		pki.listCertificates({

			// The ID of the <select> element to be populated with the certificates.
			selectId: formElements.certificateSelect.attr('id'),

			// Function that will be called to get the text that should be displayed for each option.
			selectOptionFormatter: function (cert) {
				var s = cert.subjectName + ' (issued by ' + cert.issuerName + ')';
				if (new Date() > cert.validityEnd) {
					s = '[EXPIRED] ' + s;
				}
				return s;
			}

		}).success(function () {

			// Once the certificates have been listed, unblock the UI.
			$.unblockUI();
		});
	}

	// ------------------------------------------------------------------------------------------------------
	// Function called when the user clicks the "Sign Batch" button
	// ------------------------------------------------------------------------------------------------------
	function start() {

		// Block the UI while we perform the signature.
		$.blockUI({ message: 'Signing ...' });

		// Get the thumbprint of the selected certificate.
		selectedCertThumbprint = formElements.certificateSelect.val();

		// Call Web PKI to preauthorize the signatures, so that the user only sees one confirmation dialog.
		pki.preauthorizeSignatures({

			certificateThumbprint: selectedCertThumbprint,
			signatureCount: docCount // Number of signatures to be authorized by the user.

		}).success(function () {

			// Read the selected certificate's encoding.
			pki.readCertificate(selectedCertThumbprint).success(function (certEncoded) {

				// Fill the hidden field "certificateField" with the certificate encoding.
				formElements.certificateField.val(certEncoded);

				// Fire up the click event of the button "SubmitCertificateButton" on form's code-behind
				// (server-side).
				formElements.submitCertificateButton.click();

			});
		});
	}

	// ------------------------------------------------------------------------------------------------------
	// Function that signs the current document's "to sign hash" using the selected certificate.
	// ------------------------------------------------------------------------------------------------------
	function sign() {

		// Call Web PKI passing the selected certificate, the document's "toSignHash" and the digest
		// algorithm to be used during the signature algorithm.
		pki.signHash({

			thumbprint: selectedCertThumbprint,
			hash: formElements.toSignHashField.val(),
			digestAlgorithm: formElements.digestAlgorithmField.val()

		}).success(function (signature) {

			// Fill the hidden field "signatureField" with the result of the signature algorithm.
			formElements.signatureField.val(signature);

			// Fire up the click event of the button "SubmitSignatureButton" on form's code-behind
			// (server-side).
			formElements.submitSignatureButton.click();

		});
	}

	// -------------------------------------------------------------------------------------------------
	// Function called if an error occurs on the Web PKI component.
	// -------------------------------------------------------------------------------------------------
	function onWebPkiError(message, error, origin) {
		// Unblock the UI.
		$.unblockUI();
		// Log the error to the browser console (for debugging purposes).
		if (console) {
			console.log('An error has occurred on the signature browser component: ' + message, error);
		}
		// Show the message to the user. You might want to substitute the alert below with a more
		// user-friendly UI component to show the error.
		alert(message);
	}

	return {
		setDocumentCount: setDocumentCount,
		pageLoad: pageLoad,
		refresh: refresh,
		start: start
	};

})();
