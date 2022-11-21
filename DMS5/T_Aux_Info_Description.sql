/****** Object:  Table [dbo].[T_AuxInfo_Description] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Description](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Aux_Subcategory_ID] [int] NULL,
	[Sequence] [tinyint] NOT NULL,
	[DataSize] [int] NOT NULL,
	[HelperAppend] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Active] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_AuxInfo_Description] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_AuxInfo_Description] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] ADD  CONSTRAINT [DF_T_AuxInfo_Description_Sequence]  DEFAULT (0) FOR [Sequence]
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] ADD  CONSTRAINT [DF_T_AuxInfo_Description_Size]  DEFAULT (64) FOR [DataSize]
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] ADD  CONSTRAINT [DF_T_AuxInfo_Description_HelperAppend]  DEFAULT ('N') FOR [HelperAppend]
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] ADD  CONSTRAINT [DF_T_AuxInfo_Description_Active]  DEFAULT ('Y') FOR [Active]
GO
ALTER TABLE [dbo].[T_AuxInfo_Description]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Description_T_AuxInfo_Subcategory] FOREIGN KEY([Aux_Subcategory_ID])
REFERENCES [dbo].[T_AuxInfo_Subcategory] ([ID])
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] CHECK CONSTRAINT [FK_T_AuxInfo_Description_T_AuxInfo_Subcategory]
GO
ALTER TABLE [dbo].[T_AuxInfo_Description]  WITH CHECK ADD  CONSTRAINT [CK_T_AuxInfo_Description_Active] CHECK  (([Active]='N' OR [Active]='Y'))
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] CHECK CONSTRAINT [CK_T_AuxInfo_Description_Active]
GO
