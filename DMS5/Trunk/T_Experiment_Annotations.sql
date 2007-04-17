/****** Object:  Table [dbo].[T_Experiment_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Annotations](
	[Experiment_ID] [int] NOT NULL,
	[Key_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Experiment_Annotations] PRIMARY KEY CLUSTERED 
(
	[Experiment_ID] ASC,
	[Key_Name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Experiment_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Annotations_T_Annotation_Keys] FOREIGN KEY([Key_Name])
REFERENCES [T_Annotation_Keys] ([Key_Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Experiment_Annotations]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Annotations_T_Experiments] FOREIGN KEY([Experiment_ID])
REFERENCES [T_Experiments] ([Exp_ID])
ON DELETE CASCADE
GO
