<%@ Page Title="Assinatura PAdES" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="InformacoesDeAssinatura.aspx.cs" Inherits="WebForms.PadesSignatureInfo" %>

<%@ PreviousPageType VirtualPath="~/Assinatura.aspx" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
	<h2>Assinatura de arquivos</h2>

	<p>Arquivo assinado com sucesso</p>

	<p>Informações do certificado:</p>
	<ul>
		<li>Domínio: <%= certificate.SubjectName.CommonName %></li>
		<li>Email: <%= certificate.EmailAddress %></li>
		<li>Campos ICP-Brasil
			<ul>
				<li>Tipo de certificado: <%= certificate.PkiBrazil.CertificateType %></li>
				<li>CPF: <%= certificate.PkiBrazil.CPF %></li>
				<li>Responsável: <%= certificate.PkiBrazil.Responsavel %></li>
				<li>Empresa: <%= certificate.PkiBrazil.CompanyName %></li>
				<li>CNPJ: <%= certificate.PkiBrazil.Cnpj %></li>
				<li>RG: <%= certificate.PkiBrazil.RGNumero %> <%= certificate.PkiBrazil.RGEmissor %> <%= certificate.PkiBrazil.RGEmissorUF %></li>
				<li>OAB: <%= certificate.PkiBrazil.OabNumero%> <%= certificate.PkiBrazil.OabUF %></li>
			</ul>
		</li>
	</ul>

	<h3>Ações:</h3>
	<ul>
		<li><a href="Download?file=<%= signatureFile.Replace(".", "_") %>">Baixar o arquivo</a></li>
		<li><a href="VersaoImpressa?file=<%= signatureFile %>">Versão amigável do arquivo assinado</a></li>
	</ul>
</asp:Content>
