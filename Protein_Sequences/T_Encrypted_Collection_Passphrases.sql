/****** Object:  Table [dbo].[T_Encrypted_Collection_Passphrases] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Encrypted_Collection_Passphrases](
	[Passphrase_ID] [int] IDENTITY(1,1) NOT NULL,
	[Passphrase] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Protein_Collection_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Encrypted_Collection_Passphrases] PRIMARY KEY CLUSTERED 
(
	[Passphrase_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_Guest] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_Guest] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_Guest] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_Guest] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_Guest] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
GO
DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
GO
