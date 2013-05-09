/****** Object:  Table [dbo].[T_Analysis_Job_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processors](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[State] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Processor_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Notes] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [T_Analysis_Job_Processors_PK] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY],
 CONSTRAINT [IX_T_Analysis_Job_Processors] UNIQUE CLUSTERED 
(
	[Processor_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Processors_ID_Name_State_Machine] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Processors_ID_Name_State_Machine] ON [dbo].[T_Analysis_Job_Processors] 
(
	[ID] ASC,
	[Processor_Name] ASC
)
INCLUDE ( [State],
[Machine]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Analysis_Job_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER [dbo].[trig_u_T_Analysis_Job_Processors] ON [dbo].[T_Analysis_Job_Processors] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates Last_Affected and Entered_By if any of the 
**		parameter fields are changed
**
**		Note that the SYSTEM_USER and suser_sname() functions are equivalent, with
**		 both returning the username in the form PNL\D3L243 if logged in using 
**		 integrated authentication or returning the Sql Server login name if
**		 logged in with a Sql Server login
**
**	Auth:	mem
**	Date:	02/24/2007
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	-- Note: Column Processing_State is checked below
	If	Update(State) OR
		Update(Processor_Name) OR
		Update(Machine)
	Begin
		UPDATE T_Analysis_Job_Processors
		SET Last_Affected = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_Analysis_Job_Processors INNER JOIN 
			 inserted ON T_Analysis_Job_Processors.ID = inserted.ID
	End

GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processors] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_Processors_State] CHECK  (([State]='D' OR [State]='E'))
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors] CHECK CONSTRAINT [CK_T_Analysis_Job_Processors_State]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors] ADD  CONSTRAINT [DF_T_Analysis_Job_Processors_State]  DEFAULT ('E') FOR [State]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors] ADD  CONSTRAINT [DF_T_Analysis_Job_Processors_Notes]  DEFAULT ('') FOR [Notes]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors] ADD  CONSTRAINT [DF_T_Analysis_Job_Processors_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors] ADD  CONSTRAINT [DF_T_Analysis_Job_Processors_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
