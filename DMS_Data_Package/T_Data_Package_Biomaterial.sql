/****** Object:  Table [dbo].[T_Data_Package_Biomaterial] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package_Biomaterial](
	[Data_Pkg_ID] [int] NOT NULL,
	[Biomaterial_ID] [int] NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Item_Added] [datetime] NOT NULL,
	[Package_Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Data_Package_ID]  AS ([Data_Pkg_ID]),
 CONSTRAINT [PK_T_Data_Package_Biomaterial] PRIMARY KEY CLUSTERED 
(
	[Data_Pkg_ID] ASC,
	[Biomaterial_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Package_Biomaterial] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Data_Package_Biomaterial] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package_Biomaterial] TO [DMS_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Package_Biomaterial] ADD  CONSTRAINT [DF_T_Data_Package_Biomaterial_Item Added]  DEFAULT (getdate()) FOR [Item_Added]
GO
ALTER TABLE [dbo].[T_Data_Package_Biomaterial] ADD  CONSTRAINT [DF_T_Data_Package_Biomaterial_Package Comment]  DEFAULT ('') FOR [Package_Comment]
GO
ALTER TABLE [dbo].[T_Data_Package_Biomaterial]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_Biomaterial_T_Data_Package] FOREIGN KEY([Data_Pkg_ID])
REFERENCES [dbo].[T_Data_Package] ([Data_Pkg_ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Data_Package_Biomaterial] CHECK CONSTRAINT [FK_T_Data_Package_Biomaterial_T_Data_Package]
GO
