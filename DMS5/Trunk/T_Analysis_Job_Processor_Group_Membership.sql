/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group_Membership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership](
	[Processor_ID] [int] NOT NULL,
	[Group_ID] [int] NOT NULL,
	[Membership_Enabled] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Membership_Enabled]  DEFAULT ('Y'),
	[Last_Affected] [datetime] NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Last_Affected]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [T_Analysis_Job_Processor_Group_Membership_PK] PRIMARY KEY CLUSTERED 
(
	[Processor_ID] ASC,
	[Group_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Trigger [trig_u_T_Analysis_Job_Processor_Group_Membership] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create TRIGGER dbo.trig_u_T_Analysis_Job_Processor_Group_Membership ON dbo.T_Analysis_Job_Processor_Group_Membership 
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
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Group_Membership] ([Entered_By]) TO [DMS2_SP_User]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [T_Analysis_Job_Processor_Group_T_Analysis_Job_Processor_Group_Membership_FK1] FOREIGN KEY([Group_ID])
REFERENCES [T_Analysis_Job_Processor_Group] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [T_Analysis_Job_Processors_T_Analysis_Job_Processor_Group_Membership_FK1] FOREIGN KEY([Processor_ID])
REFERENCES [T_Analysis_Job_Processors] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_Processor_Group_Membership_Enabled] CHECK  (([Membership_Enabled] = 'N' or [Membership_Enabled] = 'Y'))
GO
