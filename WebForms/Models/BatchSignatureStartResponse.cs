﻿using System;

namespace WebForms.Models {
	public class BatchSignatureStartResponse {

		public string TransferDataFileId { get; set; }

		public byte[] ToSignHash { get; set; }
		public string ToSignHashBase64
		{
			get { return ToSignHash != null ? Convert.ToBase64String(ToSignHash) : ""; }
			set { ToSignHash = !string.IsNullOrEmpty(value) ? Convert.FromBase64String(value) : null; }
		}

		public string DigestAlgorithmOid { get; set; }
	}
}