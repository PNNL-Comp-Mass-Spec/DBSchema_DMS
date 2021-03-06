/****** Object:  Table [dbo].[T_Param_File_Mass_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_File_Mass_Mods](
	[Mod_Entry_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Residue_ID] [int] NULL,
	[Local_Symbol_ID] [tinyint] NOT NULL,
	[Mass_Correction_ID] [int] NOT NULL,
	[Param_File_ID] [int] NULL,
	[Mod_Type_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MaxQuant_Mod_ID] [int] NULL,
 CONSTRAINT [PK_T_Peptide_Mod_Param_File_List_Ex] PRIMARY KEY CLUSTERED 
(
	[Mod_Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Param_File_Mass_Mods] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Param_File_Mass_Mods] TO [DMS_ParamFile_Admin] AS [dbo]
GO
/****** Object:  Index [IX_T_Param_File_Mass_Mods] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Param_File_Mass_Mods] ON [dbo].[T_Param_File_Mass_Mods]
(
	[Param_File_ID] ASC,
	[Local_Symbol_ID] ASC,
	[Residue_ID] ASC,
	[Mass_Correction_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Mass_Correction_Factors] FOREIGN KEY([Mass_Correction_ID])
REFERENCES [dbo].[T_Mass_Correction_Factors] ([Mass_Correction_ID])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Mass_Correction_Factors]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_MaxQuant_Mods] FOREIGN KEY([MaxQuant_Mod_ID])
REFERENCES [dbo].[T_MaxQuant_Mods] ([Mod_ID])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_MaxQuant_Mods]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Modification_Types] FOREIGN KEY([Mod_Type_Symbol])
REFERENCES [dbo].[T_Modification_Types] ([Mod_Type_Symbol])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Modification_Types]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Param_Files] FOREIGN KEY([Param_File_ID])
REFERENCES [dbo].[T_Param_Files] ([Param_File_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Param_Files]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Residues] FOREIGN KEY([Residue_ID])
REFERENCES [dbo].[T_Residues] ([Residue_ID])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Residues]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Seq_Local_Symbols_List] FOREIGN KEY([Local_Symbol_ID])
REFERENCES [dbo].[T_Seq_Local_Symbols_List] ([Local_Symbol_ID])
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [FK_T_Param_File_Mass_Mods_T_Seq_Local_Symbols_List]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [CK_T_Param_File_Mass_Mods_DynMod_LocalSymbolID] CHECK  ((case when [Mod_Type_Symbol]='D' then [Local_Symbol_ID] else (1) end>(0)))
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [CK_T_Param_File_Mass_Mods_DynMod_LocalSymbolID]
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods]  WITH CHECK ADD  CONSTRAINT [CK_T_Param_File_Mass_Mods_StatMod_LocalSymbolID] CHECK  ((case when [Mod_Type_Symbol]='T' OR [Mod_Type_Symbol]='S' then [Local_Symbol_ID] else (0) end=(0)))
GO
ALTER TABLE [dbo].[T_Param_File_Mass_Mods] CHECK CONSTRAINT [CK_T_Param_File_Mass_Mods_StatMod_LocalSymbolID]
GO
