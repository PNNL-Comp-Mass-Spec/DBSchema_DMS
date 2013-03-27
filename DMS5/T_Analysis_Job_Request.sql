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
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Request_AJR_RequestID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Request_AJR_RequestID] ON [dbo].[T_Analysis_Job_Request] 
(
	[AJR_requestID] ASC
)
INCLUDE ( [AJR_workPackage]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_Request_State_Created]    Script Date: 03/26/2013 17:37:49 ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Request_State_Created] ON [dbo].[T_Analysis_Job_Request] 
(
	[AJR_state] ASC,
	[AJR_created] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_d_AnalysisJobRequest]    Script Date: 03/26/2013 17:37:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger [dbo].[trig_d_AnalysisJobRequest] on [dbo].[T_Analysis_Job_Request]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the deleted analysis job request
**
**	Auth:	mem
**	Date:	Initial version
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Event_Log for each job request deleted from T_Analysis_Job_Request
	INSERT INTO T_Event_Log
		(
			Target_Type, 
			Target_ID, 
			Target_State, 
			Prev_Target_State, 
			Entered,
			Entered_By
		)
	SELECT 12 AS Target_Type,
	       deleted.AJR_requestID AS Target_ID,
	       0 AS Target_State,
	       deleted.AJR_state AS Prev_Target_State,
	       GETDATE(),
           suser_sname() + '; ' + ISNULL(deleted.AJR_requestName, '??')
	FROM deleted	   
	ORDER BY deleted.AJR_requestID


GO

/****** Object:  Trigger [dbo].[trig_i_AnalysisJobRequest]    Script Date: 03/26/2013 17:37:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger [dbo].[trig_i_AnalysisJobRequest] on [dbo].[T_Analysis_Job_Request]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the new analysis job request
**
**	Auth:	mem
**	Date:	Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On
	
	INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
	SELECT 12, inserted.AJR_requestID, inserted.AJR_state, 0, GetDate()
	FROM inserted
	ORDER BY inserted.AJR_requestID


GO

/****** Object:  Trigger [dbo].[trig_u_AnalysisJobRequest]    Script Date: 03/26/2013 17:37:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger [dbo].[trig_u_AnalysisJobRequest] on [dbo].[T_Analysis_Job_Request]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Event_Log for the updated analysis job request
**
**	Auth:	mem
**	Date:	03/26/2013 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On
	
	If Update(AJR_state)
	Begin
		INSERT INTO T_Event_Log	(Target_Type, Target_ID, Target_State, Prev_Target_State, Entered)
		SELECT 12, inserted.AJR_requestID, inserted.AJR_state, deleted.AJR_state, GetDate()
		FROM deleted INNER JOIN inserted ON deleted.AJR_requestID = inserted.AJR_requestID
		WHERE inserted.AJR_state <> deleted.AJR_state
		ORDER BY inserted.AJR_requestID

	End


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
