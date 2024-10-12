/****** Object:  Table [dbo].[T_Data_Analysis_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Analysis_Request](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Request_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Analysis_Type] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Requester_PRN] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Analysis_Specifications] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Representative_Batch_ID] [int] NULL,
	[Representative_Data_Pkg_ID] [int] NULL,
	[Exp_Group_ID] [int] NULL,
	[Work_Package] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Assigned_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Priority] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reason_For_High_Priority] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Estimated_Analysis_Time_Days] [int] NOT NULL,
	[State] [tinyint] NOT NULL,
	[State_Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[State_Changed] [datetime] NOT NULL,
	[Closed] [datetime] NULL,
	[Campaign] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Organism] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_Count] [int] NULL,
 CONSTRAINT [PK_T_Data_Analysis_Request] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Analysis_Request] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_Analysis_Type]  DEFAULT ('Metabolomics') FOR [Analysis_Type]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_Assigned_Personnel]  DEFAULT ('') FOR [Assigned_Personnel]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_Priority]  DEFAULT ('Normal') FOR [Priority]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF__Data_Analysis_Request_Estimated_Analysis_Time_Days]  DEFAULT ((1)) FOR [Estimated_Analysis_Time_Days]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_State]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_State_Changed]  DEFAULT (getdate()) FOR [State_Changed]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_T_Data_Analysis_Request_Type_Name] FOREIGN KEY([Analysis_Type])
REFERENCES [dbo].[T_Data_Analysis_Request_Type_Name] ([Analysis_Type])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_T_Data_Analysis_Request_Type_Name]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_T_Experiment_Groups] FOREIGN KEY([Exp_Group_ID])
REFERENCES [dbo].[T_Experiment_Groups] ([Group_ID])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_T_Experiment_Groups]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_T_Requested_Run_Batches] FOREIGN KEY([Representative_Batch_ID])
REFERENCES [dbo].[T_Requested_Run_Batches] ([ID])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_T_Requested_Run_Batches]
GO
/****** Object:  Trigger [dbo].[trig_d_Data_Analysis_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_Data_Analysis_Request] on [dbo].[T_Data_Analysis_Request]
For Delete
/****************************************************
**
**  Desc:
**      Makes an entry in T_Data_Analysis_Request_Updates for the deleted data analysis request
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version
**    
*****************************************************/
AS
    Set NoCount On

    -- Add entries to T_Data_Analysis_Request_Updates for each entry deleted from T_Data_Analysis_Request
    INSERT INTO T_Data_Analysis_Request_Updates( Request_ID,
                                                 Entered_By,
                                                 Old_State_ID,
                                                 New_State_ID )
    SELECT deleted.ID,
           dbo.get_user_login_without_domain('') + '; ' + ISNULL(deleted.Request_Name, 'Unknown Request'),
           deleted.state,
           0 AS New_State_ID
    FROM deleted
    ORDER BY deleted.ID

GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ENABLE TRIGGER [trig_d_Data_Analysis_Request]
GO
/****** Object:  Trigger [dbo].[trig_i_Data_Analysis_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_i_Data_Analysis_Request] on [dbo].[T_Data_Analysis_Request]
For Insert
/****************************************************
**
**  Desc: 
**      Makes an entry in T_Data_Analysis_Request_Updates for the new data analysis request
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version
**    
*****************************************************/
AS
    If @@RowCount = 0
        Return

    Set NoCount On

    INSERT INTO T_Data_Analysis_Request_Updates( Request_ID,
                                                 Entered_By,
                                                 Old_State_ID,
                                                 New_State_ID )
    SELECT inserted.ID,
           dbo.get_user_login_without_domain(''),
           0,
           inserted.state
    FROM inserted
    ORDER BY inserted.ID

GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ENABLE TRIGGER [trig_i_Data_Analysis_Request]
GO
/****** Object:  Trigger [dbo].[trig_u_Data_Analysis_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_u_Data_Analysis_Request] on [dbo].[T_Data_Analysis_Request]
For Update
/****************************************************
**
**  Desc: 
**      Makes an entry in T_Data_Analysis_Request_Updates for the updated data analysis request
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version
**    
*****************************************************/
AS
    If @@RowCount = 0
        Return

    INSERT INTO T_Data_Analysis_Request_Updates( Request_ID,
                                                 Entered_By,
                                                 Old_State_ID,
                                                 New_State_ID )
    SELECT inserted.ID,
           dbo.get_user_login_without_domain(''),
           deleted.state,
           inserted.state
    FROM deleted
         INNER JOIN inserted
           ON deleted.ID = inserted.ID
    WHERE inserted.state <> deleted.state OR
          inserted.state = deleted.state AND
          dbo.get_user_login_without_domain('') <> 'msdadmin'
    ORDER BY inserted.ID

GO
ALTER TABLE [dbo].[T_Data_Analysis_Request] ENABLE TRIGGER [trig_u_Data_Analysis_Request]
GO
