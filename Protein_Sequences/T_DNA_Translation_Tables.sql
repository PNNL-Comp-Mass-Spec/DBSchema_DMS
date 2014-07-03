/****** Object:  Table [dbo].[T_DNA_Translation_Tables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DNA_Translation_Tables](
	[Translation_Table_Name_ID] [int] IDENTITY(1,1) NOT NULL,
	[Translation_Table_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DNA_Translation_Table_ID] [int] NULL,
 CONSTRAINT [PK_T_DNA_Translation_Tables] PRIMARY KEY CLUSTERED 
(
	[Translation_Table_Name_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_DNA_Translation_Tables]  WITH CHECK ADD  CONSTRAINT [FK_T_DNA_Translation_Tables_T_DNA_Translation_Table_Map] FOREIGN KEY([DNA_Translation_Table_ID])
REFERENCES [dbo].[T_DNA_Translation_Table_Map] ([DNA_Translation_Table_ID])
GO
ALTER TABLE [dbo].[T_DNA_Translation_Tables] CHECK CONSTRAINT [FK_T_DNA_Translation_Tables_T_DNA_Translation_Table_Map]
GO
