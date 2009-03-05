/****** Object:  Table [dbo].[T_Analysis_Job_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processors](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[State] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processors_State]  DEFAULT ('E'),
	[Processor_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Notes] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processors_Notes]  DEFAULT (''),
	[Last_Affected] [datetime] NULL CONSTRAINT [DF_T_Analysis_Job_Processors_Last_Affected]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processors_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [T_Analysis_Job_Processors_PK] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_T_Analysis_Job_Processors] UNIQUE CLUSTERED 
(
	[Processor_Name] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Processors_ID_Name_State_Machine] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Processors_ID_Name_State_Machine] ON [dbo].[T_Analysis_Job_Processors] 
(
	[ID] ASC,
	[Processor_Name] ASC
)
INCLUDE ( [State],
[Machine]) WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Trigger [trig_u_T_Analysis_Job_Processors] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create TRIGGER dbo.trig_u_T_Analysis_Job_Processors ON dbo.T_Analysis_Job_Processors 
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
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processors] ([Entered_By]) TO [DMS2_SP_User]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_Processors_State] CHECK  (([State]='D' OR [State]='E'))
GO
