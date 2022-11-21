/****** Object:  Table [dbo].[T_Aux_Info_Subcategory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Aux_Info_Subcategory](
	[Aux_Subcategory_ID] [int] IDENTITY(100,1) NOT NULL,
	[Aux_Subcategory] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Aux_Category_ID] [int] NULL,
	[Sequence] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_AuxInfo_Subcategory] PRIMARY KEY CLUSTERED 
(
	[Aux_Subcategory_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Aux_Info_Subcategory] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Aux_Info_Subcategory] ADD  CONSTRAINT [DF_T_AuxInfo_Subcategory_Sequence]  DEFAULT (0) FOR [Sequence]
GO
ALTER TABLE [dbo].[T_Aux_Info_Subcategory]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Subcategory_T_AuxInfo_Category] FOREIGN KEY([Aux_Category_ID])
REFERENCES [dbo].[T_Aux_Info_Category] ([Aux_Category_ID])
GO
ALTER TABLE [dbo].[T_Aux_Info_Subcategory] CHECK CONSTRAINT [FK_T_AuxInfo_Subcategory_T_AuxInfo_Category]
GO
