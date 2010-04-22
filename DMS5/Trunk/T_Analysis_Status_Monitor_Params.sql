/****** Object:  Table [dbo].[T_Analysis_Status_Monitor_Params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Status_Monitor_Params](
	[ProcessorID] [int] NOT NULL,
	[StatusFileNamePath] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CheckBoxState] [tinyint] NOT NULL,
	[UseForStatusCheck] [tinyint] NOT NULL,
 CONSTRAINT [IX_T_Analysis_Status_Monitor_Params] UNIQUE NONCLUSTERED 
(
	[ProcessorID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Status_Monitor_Params]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Status_Monitor_Params_T_Analysis_Job_Processors] FOREIGN KEY([ProcessorID])
REFERENCES [T_Analysis_Job_Processors] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Status_Monitor_Params] CHECK CONSTRAINT [FK_T_Analysis_Status_Monitor_Params_T_Analysis_Job_Processors]
GO
ALTER TABLE [dbo].[T_Analysis_Status_Monitor_Params] ADD  CONSTRAINT [DF_T_Analysis_Status_Monitor_Params_CheckBoxState]  DEFAULT (0) FOR [CheckBoxState]
GO
ALTER TABLE [dbo].[T_Analysis_Status_Monitor_Params] ADD  CONSTRAINT [DF_T_Analysis_Status_Monitor_Params_UseForStatusCheck]  DEFAULT (1) FOR [UseForStatusCheck]
GO
