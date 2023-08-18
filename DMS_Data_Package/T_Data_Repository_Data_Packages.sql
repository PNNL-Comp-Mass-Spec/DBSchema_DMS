/****** Object:  Table [dbo].[T_Data_Repository_Data_Packages] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Repository_Data_Packages](
	[Upload_ID] [int] NOT NULL,
	[Data_Pkg_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Data_Repository_Data_Packages] PRIMARY KEY CLUSTERED 
(
	[Upload_ID] ASC,
	[Data_Pkg_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Data_Repository_Data_Packages]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Repository_Data_Packages_T_Data_Package] FOREIGN KEY([Data_Pkg_ID])
REFERENCES [dbo].[T_Data_Package] ([Data_Pkg_ID])
GO
ALTER TABLE [dbo].[T_Data_Repository_Data_Packages] CHECK CONSTRAINT [FK_T_Data_Repository_Data_Packages_T_Data_Package]
GO
ALTER TABLE [dbo].[T_Data_Repository_Data_Packages]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Repository_Data_Packages_T_Data_Repository_Uploads] FOREIGN KEY([Upload_ID])
REFERENCES [dbo].[T_Data_Repository_Uploads] ([Upload_ID])
GO
ALTER TABLE [dbo].[T_Data_Repository_Data_Packages] CHECK CONSTRAINT [FK_T_Data_Repository_Data_Packages_T_Data_Repository_Uploads]
GO
