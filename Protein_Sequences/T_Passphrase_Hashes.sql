/****** Object:  Table [dbo].[T_Passphrase_Hashes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Passphrase_Hashes](
	[Passphrase_Hash_ID] [int] IDENTITY(1,1) NOT NULL,
	[Passphrase_SHA1_Hash] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Protein_Collection_ID] [int] NOT NULL,
	[Passphrase_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Passphrase_Hashes] PRIMARY KEY CLUSTERED 
(
	[Passphrase_Hash_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
DENY DELETE ON [dbo].[T_Passphrase_Hashes] TO [DMSReader] AS [dbo]
GO
DENY INSERT ON [dbo].[T_Passphrase_Hashes] TO [DMSReader] AS [dbo]
GO
DENY REFERENCES ON [dbo].[T_Passphrase_Hashes] TO [DMSReader] AS [dbo]
GO
DENY SELECT ON [dbo].[T_Passphrase_Hashes] TO [DMSReader] AS [dbo]
GO
DENY UPDATE ON [dbo].[T_Passphrase_Hashes] TO [DMSReader] AS [dbo]
GO
