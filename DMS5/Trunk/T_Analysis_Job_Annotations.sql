/****** Object:  Table [dbo].[T_Analysis_Job_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Annotations](
	[Job_ID] [int] NOT NULL,
	[Key_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Analysis_Job_Annotations] PRIMARY KEY CLUSTERED 
(
	[Job_ID] ASC,
	[Key_Name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Annotations_T_Analysis_Job] FOREIGN KEY([Job_ID])
REFERENCES [T_Analysis_Job] ([AJ_jobID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Job_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Annotations_T_Annotation_Keys] FOREIGN KEY([Key_Name])
REFERENCES [T_Annotation_Keys] ([Key_Name])
ON UPDATE CASCADE
GO
