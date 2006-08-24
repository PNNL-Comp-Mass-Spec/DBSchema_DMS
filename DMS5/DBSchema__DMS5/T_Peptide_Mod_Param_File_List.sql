/****** Object:  Table [dbo].[T_Peptide_Mod_Param_File_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Peptide_Mod_Param_File_List](
	[Local_Symbol_ID] [tinyint] NOT NULL,
	[Mod_ID] [int] NOT NULL,
	[RefNum] [int] IDENTITY(2000,1) NOT NULL,
	[Param_File_ID] [int] NULL,
 CONSTRAINT [PK_T_Peptide_Mod_Param_File_List] PRIMARY KEY NONCLUSTERED 
(
	[RefNum] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Peptide_Mod_Param_File_List]  WITH CHECK ADD  CONSTRAINT [FK_T_Peptide_Mod_Param_File_List_T_Param_Files] FOREIGN KEY([Param_File_ID])
REFERENCES [T_Param_Files] ([Param_File_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Peptide_Mod_Param_File_List]  WITH CHECK ADD  CONSTRAINT [FK_T_Peptide_Mod_Param_File_List_T_Peptide_Mod_Global_List] FOREIGN KEY([Mod_ID])
REFERENCES [T_Peptide_Mod_Global_List] ([Mod_ID])
GO
ALTER TABLE [dbo].[T_Peptide_Mod_Param_File_List]  WITH CHECK ADD  CONSTRAINT [FK_T_Peptide_Mod_Param_File_List_T_Seq_Local_Symbols_List] FOREIGN KEY([Local_Symbol_ID])
REFERENCES [T_Seq_Local_Symbols_List] ([Local_Symbol_ID])
GO
