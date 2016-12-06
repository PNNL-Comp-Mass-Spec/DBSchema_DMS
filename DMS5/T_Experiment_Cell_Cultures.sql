/****** Object:  Table [dbo].[T_Experiment_Cell_Cultures] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Cell_Cultures](
	[Exp_ID] [int] NOT NULL,
	[CC_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Experiment_Cell_Cultures] PRIMARY KEY CLUSTERED 
(
	[Exp_ID] ASC,
	[CC_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Experiment_Cell_Cultures] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Experiment_Cell_Cultures]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Cell_Cultures_T_Cell_Culture] FOREIGN KEY([CC_ID])
REFERENCES [dbo].[T_Cell_Culture] ([CC_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Cell_Cultures] CHECK CONSTRAINT [FK_T_Experiment_Cell_Cultures_T_Cell_Culture]
GO
ALTER TABLE [dbo].[T_Experiment_Cell_Cultures]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Cell_Cultures_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Cell_Cultures] CHECK CONSTRAINT [FK_T_Experiment_Cell_Cultures_T_Experiments]
GO
