/****** Object:  Table [dbo].[T_Automatic_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Automatic_Jobs](
	[Script_For_Completed_Job] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Script_For_New_Job] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Automatic_Jobs] PRIMARY KEY CLUSTERED 
(
	[Script_For_Completed_Job] ASC,
	[Script_For_New_Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Automatic_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_T_Automatic_Jobs_T_Scripts] FOREIGN KEY([Script_For_Completed_Job])
REFERENCES [T_Scripts] ([Script])
GO
ALTER TABLE [dbo].[T_Automatic_Jobs] CHECK CONSTRAINT [FK_T_Automatic_Jobs_T_Scripts]
GO
ALTER TABLE [dbo].[T_Automatic_Jobs]  WITH CHECK ADD  CONSTRAINT [FK_T_Automatic_Jobs_T_Scripts1] FOREIGN KEY([Script_For_New_Job])
REFERENCES [T_Scripts] ([Script])
GO
ALTER TABLE [dbo].[T_Automatic_Jobs] CHECK CONSTRAINT [FK_T_Automatic_Jobs_T_Scripts1]
GO
