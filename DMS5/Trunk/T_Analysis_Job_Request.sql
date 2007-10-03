/****** Object:  Table [dbo].[T_Analysis_Job_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Request](
	[AJR_requestID] [int] IDENTITY(1000,1) NOT NULL,
	[AJR_requestName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_created] [smalldatetime] NOT NULL,
	[AJR_analysisToolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_parmFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_settingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJR_organismDBName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_organism_ID] [int] NOT NULL,
	[AJR_datasets] [varchar](6000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJR_requestor] [int] NOT NULL,
	[AJR_comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJR_state] [int] NOT NULL CONSTRAINT [DF_T_Analysis_Job_Request_AJR_state]  DEFAULT (0),
	[AJR_proteinCollectionList] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_AJR_proteinCollectionList]  DEFAULT ('na'),
	[AJR_proteinOptionsList] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_AJR_proteinOptionsList]  DEFAULT ('na'),
	[AJR_workPackage] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [T_Analysis_Job_Request_PK] PRIMARY KEY CLUSTERED 
(
	[AJR_requestID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Request_State_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Request_State_Created] ON [dbo].[T_Analysis_Job_Request] 
(
	[AJR_state] ASC,
	[AJR_created] ASC
) ON [PRIMARY]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_requestID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_requestID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_requestName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_requestName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_analysisToolName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_analysisToolName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_parmFileName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_parmFileName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_settingsFileName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_settingsFileName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_organismDBName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_organismDBName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_organism_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_organism_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_datasets]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_datasets]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_requestor]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_requestor]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_state]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_state]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_proteinCollectionList]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_proteinCollectionList]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_proteinOptionsList]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_proteinOptionsList]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request] ([AJR_workPackage]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request] ([AJR_workPackage]) TO [Limited_Table_Write]
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
