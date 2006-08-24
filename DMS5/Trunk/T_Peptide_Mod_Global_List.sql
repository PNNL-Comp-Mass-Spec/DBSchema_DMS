/****** Object:  Table [dbo].[T_Peptide_Mod_Global_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Peptide_Mod_Global_List](
	[Mod_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Symbol] [char](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SD_Flag] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mass_Correction_Factor] [float] NULL,
	[Affected_Residues] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Peptide_Mod_Global_List_Affected_Residues]  DEFAULT (''),
 CONSTRAINT [PK_T_Peptide_Mod_Global_List] PRIMARY KEY CLUSTERED 
(
	[Mod_ID] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_Peptide_Mod_Global_List_Residue_and_Mass] UNIQUE NONCLUSTERED 
(
	[SD_Flag] ASC,
	[Affected_Residues] ASC,
	[Mass_Correction_Factor] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_Peptide_Mod_Global_List_Symbol_and_SD] UNIQUE NONCLUSTERED 
(
	[Symbol] ASC,
	[SD_Flag] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Peptide_Mod_Global_List]  WITH CHECK ADD  CONSTRAINT [CK_T_Peptide_Mod_Global_List_Symbol] CHECK  ((((not([Symbol] like '%:%')))))
GO
