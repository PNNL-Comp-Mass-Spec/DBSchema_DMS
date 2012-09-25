/****** Object:  Table [dbo].[T_Analysis_Job_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Request](
	[AJR_requestID] [int] IDENTITY(1000,1) NOT NULL,
	[AJR_requestName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_created] [datetime] NOT NULL,
	[AJR_analysisToolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_parmFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_settingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJR_organismDBName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJR_organism_ID] [int] NOT NULL,
	[AJR_datasets] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_requestor] [int] NOT NULL,
	[AJR_comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJR_state] [int] NOT NULL,
	[AJR_proteinCollectionList] [varchar](2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_proteinOptionsList] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_workPackage] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJR_jobCount] [int] NULL,
	[AJR_specialProcessing] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [T_Analysis_Job_Request_PK] PRIMARY KEY CLUSTERED 
(
	[AJR_requestID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Request_AJR_RequestID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Request_AJR_RequestID] ON [dbo].[T_Analysis_Job_Request] 
(
	[AJR_requestID] ASC
)
INCLUDE ( [AJR_workPackage]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_Request_State_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Request_State_Created] ON [dbo].[T_Analysis_Job_Request] 
(
	[AJR_state] ASC,
	[AJR_created] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Request_T_Analysis_Job_Request_State] FOREIGN KEY([AJR_state])
REFERENCES [T_Analysis_Job_Request_State] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] CHECK CONSTRAINT [FK_T_Analysis_Job_Request_T_Analysis_Job_Request_State]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Request_T_Organisms] FOREIGN KEY([AJR_organism_ID])
REFERENCES [T_Organisms] ([Organism_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] CHECK CONSTRAINT [FK_T_Analysis_Job_Request_T_Organisms]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Request_T_Users] FOREIGN KEY([AJR_requestor])
REFERENCES [T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] CHECK CONSTRAINT [FK_T_Analysis_Job_Request_T_Users]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] ADD  CONSTRAINT [DF_T_Analysis_Job_Request_AJR_state]  DEFAULT ((0)) FOR [AJR_state]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] ADD  CONSTRAINT [DF_T_Analysis_Job_AJR_proteinCollectionList]  DEFAULT ('na') FOR [AJR_proteinCollectionList]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] ADD  CONSTRAINT [DF_T_Analysis_Job_AJR_proteinOptionsList]  DEFAULT ('na') FOR [AJR_proteinOptionsList]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Request] ADD  CONSTRAINT [DF_T_Analysis_Job_Request_AJR_jobCount]  DEFAULT ((0)) FOR [AJR_jobCount]
GO
