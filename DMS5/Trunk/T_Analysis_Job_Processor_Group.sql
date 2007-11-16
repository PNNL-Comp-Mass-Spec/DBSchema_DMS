/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Group_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Group_Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Group_Enabled] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Group_Enabled]  DEFAULT ('Y'),
	[Group_Created] [datetime] NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Group_Created]  DEFAULT (getdate()),
	[Available_For_General_Processing] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Available_For_General_Processing]  DEFAULT ('Y'),
	[Last_Affected] [datetime] NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Last_Affected]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [T_Analysis_Job_Processor_Group_PK] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
 CONSTRAINT [IX_T_Analysis_Job_Processor_Group] UNIQUE NONCLUSTERED 
(
	[Group_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Trigger [dbo].[trig_u_T_Analysis_Job_Processor_Group] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create TRIGGER dbo.trig_u_T_Analysis_Job_Processor_Group ON dbo.T_Analysis_Job_Processor_Group 
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
	If	Update(Group_Name) OR
		Update(Group_Enabled) OR
		Update(Available_For_General_Processing)
	Begin
		UPDATE T_Analysis_Job_Processor_Group
		SET Last_Affected = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_Analysis_Job_Processor_Group INNER JOIN 
			 inserted ON T_Analysis_Job_Processor_Group.ID = inserted.ID
	End

GO
