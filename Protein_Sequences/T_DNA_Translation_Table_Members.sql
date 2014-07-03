/****** Object:  Table [dbo].[T_DNA_Translation_Table_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DNA_Translation_Table_Members](
	[Translation_Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Coded_AA] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start_Sequence] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Base_1] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Base_2] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Base_3] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DNA_Translation_Table_ID] [int] NULL,
 CONSTRAINT [PK_T_DNA_Translation_Table_Members] PRIMARY KEY CLUSTERED 
(
	[Translation_Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_DNA_Translation_Table_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_DNA_Translation_Table_Members_T_DNA_Translation_Table_Map] FOREIGN KEY([DNA_Translation_Table_ID])
REFERENCES [dbo].[T_DNA_Translation_Table_Map] ([DNA_Translation_Table_ID])
GO
ALTER TABLE [dbo].[T_DNA_Translation_Table_Members] CHECK CONSTRAINT [FK_T_DNA_Translation_Table_Members_T_DNA_Translation_Table_Map]
GO
