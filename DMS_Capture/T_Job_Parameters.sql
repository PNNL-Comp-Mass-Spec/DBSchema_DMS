/****** Object:  Table [dbo].[T_Job_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Parameters](
	[Job] [int] NOT NULL,
	[Parameters] [xml] NULL,
 CONSTRAINT [PK_T_Job_Parameters] PRIMARY KEY CLUSTERED 
(
	[Job] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Job_Parameters]  WITH CHECK ADD  CONSTRAINT [FK_T_Job_Parameters_T_Jobs] FOREIGN KEY([Job])
REFERENCES [T_Jobs] ([Job])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Job_Parameters] CHECK CONSTRAINT [FK_T_Job_Parameters_T_Jobs]
GO
