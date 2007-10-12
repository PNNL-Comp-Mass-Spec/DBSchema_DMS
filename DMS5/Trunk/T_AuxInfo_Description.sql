/****** Object:  Table [dbo].[T_AuxInfo_Description] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Description](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Parent_ID] [int] NULL,
	[Sequence] [tinyint] NOT NULL CONSTRAINT [DF_T_AuxInfo_Description_Sequence]  DEFAULT (0),
	[DataSize] [int] NOT NULL CONSTRAINT [DF_T_AuxInfo_Description_Size]  DEFAULT (64),
	[HelperAppend] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_AuxInfo_Description_HelperAppend]  DEFAULT ('N'),
 CONSTRAINT [PK_T_AuxInfo_Description] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_AuxInfo_Description]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Description_T_AuxInfo_Subcategory] FOREIGN KEY([Parent_ID])
REFERENCES [T_AuxInfo_Subcategory] ([ID])
GO
ALTER TABLE [dbo].[T_AuxInfo_Description] CHECK CONSTRAINT [FK_T_AuxInfo_Description_T_AuxInfo_Subcategory]
GO
