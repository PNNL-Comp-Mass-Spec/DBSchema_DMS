/****** Object:  Table [dbo].[T_Experiment_Reference_Compounds] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Reference_Compounds](
	[Exp_ID] [int] NOT NULL,
	[Compound_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Experiment_Reference_Compounds] PRIMARY KEY CLUSTERED 
(
	[Exp_ID] ASC,
	[Compound_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Experiment_Reference_Compounds] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Experiment_Reference_Compounds]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Reference_Compounds_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Reference_Compounds] CHECK CONSTRAINT [FK_T_Experiment_Reference_Compounds_T_Experiments]
GO
ALTER TABLE [dbo].[T_Experiment_Reference_Compounds]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Reference_Compounds_T_Reference_Compound] FOREIGN KEY([Compound_ID])
REFERENCES [dbo].[T_Reference_Compound] ([Compound_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Reference_Compounds] CHECK CONSTRAINT [FK_T_Experiment_Reference_Compounds_T_Reference_Compound]
GO
