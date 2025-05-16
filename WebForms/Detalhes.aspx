<%@ Page Title="Abrir Assinatura PAdES" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Detalhes.aspx.cs" Inherits="WebForms.OpenPadesSignature" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

	<h2>Abrir assinatura PAdES existente</h2>

	<h3>O arquivo contém <%= Model.Signers.Count %> assinaturas:</h3>

	<div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">

		<%
		   for (var i = 0; i < Model.Signers.Count; i++) {
			   var signer = Model.Signers[i];
			   var collapseId = string.Format("signer_{0}_collapse", i);
			   var headingId = string.Format("signer_{0}_heading", i);

		%>
			<div class="panel panel-default">
				<div class="panel-heading" role="tab" id="<%= headingId %>">
					<h4 class="panel-title">
						<a class="collapsed" role="button" data-toggle="collapse" data-parent="#accordion" href="#<%= collapseId %>" aria-expanded="true" aria-controls="<%= collapseId %>"><%= signer.Certificate.SubjectName.CommonName %>
							<% if (signer.ValidationResults != null) { %>
								<span>- </span>
								<% if (signer.ValidationResults.IsValid) { %>
									<span style="color: green; font-weight: bold;">válida</span>
								<% } else { %>
									<span style="color: red; font-weight: bold;">inválida</span>
								<% } %>
							<% } %>
						</a>
					</h4>
				</div>
				<div id="<%= collapseId %>" class="panel-collapse collapse" role="tabpanel" aria-labelledby="<%= headingId %>">
					<div class="panel-body">
						<% if (signer.SigningTime.HasValue) { %>
							<p>Data da assinatura: <%= TimeZoneInfo.ConvertTime(signer.SigningTime.Value, WebForms.PrinterFriendlyVersion.TimeZone).ToString(WebForms.PrinterFriendlyVersion.DateFormat, WebForms.PrinterFriendlyVersion.CultureInfo) %> (<%= WebForms.PrinterFriendlyVersion.TimeZoneDisplayName %>)</p>
						<% } %>
						<p>Resumo da mensagem: <%= signer.MessageDigest.Algorithm %> <%= BitConverter.ToString(signer.MessageDigest.Value) %></p>
						<% if (signer.SignaturePolicy != null) { %>
							<p>Política de assinatura: <%= signer.SignaturePolicy.Oid %></p>
						<% } %>
				
						<p>Informações do signatário:</p>
					
						<ul>
							<li>Assunto: <%= signer.Certificate.SubjectName.CommonName %></li>
							<li>Email: <%= signer.Certificate.EmailAddress %></li>
							<li>Campos ICP-Brasil
							
								<ul>
									<li>Tipo de certificado: <%= signer.Certificate.PkiBrazil.CertificateType %></li>
									<li>CPF: <%= signer.Certificate.PkiBrazil.Cpf %></li>
									<li>Responsavel: <%= signer.Certificate.PkiBrazil.Responsavel %></li>
									<li>Empresa: <%= signer.Certificate.PkiBrazil.CompanyName %></li>
									<li>CNPJ: <%= signer.Certificate.PkiBrazil.Cnpj %></li>
									<li>RG: <%= signer.Certificate.PkiBrazil.RGNumero %> <%= signer.Certificate.PkiBrazil.RGEmissor %> <%= signer.Certificate.PkiBrazil.RGEmissorUF %></li>
									<li>OAB: <%= signer.Certificate.PkiBrazil.OabNumero %> <%= signer.Certificate.PkiBrazil.OabUF %></li>
								</ul>
							</li>
						</ul>

						<% if (signer.ValidationResults != null) { %>
					
							<p>
								Resultados da validação:<br />
								<textarea style="width: 100%" rows="20"><%= signer.ValidationResults.ToString() %></textarea>
							</p>
						<% } %>
			
					</div>
				</div>
			</div>
		<% } %>
	</div>
</asp:Content>
