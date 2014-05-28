/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group_Membership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership](
	[Processor_ID] [int] NOT NULL,
	[Group_ID] [int] NOT NULL,
	[Membership_Enabled] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Affected] [datetime] NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [T_Analysis_Job_Processor_Group_Membership_PK] PRIMARY KEY CLUSTERED 
(
	[Processor_ID] ASC,
	[Group_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group_Membership] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Analysis_Job_Processor_Group_Membership_GroupID_Enabled] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Processor_Group_Membership_GroupID_Enabled] ON [dbo].[T_Analysis_Job_Processor_Group_Membership]
(
	[Group_ID] ASC,
	[Membership_Enabled] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership] ADD  CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Membership_Enabled]  DEFAULT ('Y') FOR [Membership_Enabled]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership] ADD  CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership] ADD  CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [T_Analysis_Job_Processor_Group_T_Analysis_Job_Processor_Group_Membership_FK1] FOREIGN KEY([Group_ID])
REFERENCES [dbo].[T_Analysis_Job_Processor_Group] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership] CHECK CONSTRAINT [T_Analysis_Job_Processor_Group_T_Analysis_Job_Processor_Group_Membership_FK1]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [T_Analysis_Job_Processors_T_Analysis_Job_Processor_Group_Membership_FK1] FOREIGN KEY([Processor_ID])
REFERENCES [dbo].[T_Analysis_Job_Processors] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership] CHECK CONSTRAINT [T_Analysis_Job_Processors_T_Analysis_Job_Processor_Group_Membership_FK1]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_Processor_Group_Membership_Enabled] CHECK  (([Membership_Enabled] = 'N' or [Membership_Enabled] = 'Y'))
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership] CHECK CONSTRAINT [CK_T_Analysis_Job_Processor_Group_Membership_Enabled]
GO
/****** Object:  Trigger [dbo].[trig_u_T_Analysis_Job_Processor_Group_Membership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create TRIGGER [dbo].[trig_u_T_Analysis_Job_Processor_Group_Membership] ON [dbo].[T_Analysis_Job_Processor_Group_Membership] 
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
	If	Update(Processor_ID) OR
		Update(Group_ID) OR
		Update(Membership_Enabled)
	Begin
		UPDATE T_Analysis_Job_Processor_Group_Membership
		SET Last_Affected = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_Analysis_Job_Processor_Group_Membership AJPGM INNER JOIN 
			 inserted ON AJPGM.Processor_ID = inserted.Processor_ID AND 
			 AJPGM.Group_ID = inserted.Group_ID
	End

GO
