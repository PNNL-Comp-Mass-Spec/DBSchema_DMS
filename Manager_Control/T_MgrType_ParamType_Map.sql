/****** Object:  Table [dbo].[T_MgrType_ParamType_Map] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MgrType_ParamType_Map](
	[MgrTypeID] [int] NOT NULL,
	[ParamTypeID] [int] NOT NULL,
	[DefaultValue] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_MgrType_ParamType_Map] PRIMARY KEY CLUSTERED 
(
	[MgrTypeID] ASC,
	[ParamTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_MgrType_ParamType_Map] ADD  CONSTRAINT [DF_T_MgrType_ParamType_Map_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_MgrType_ParamType_Map] ADD  CONSTRAINT [DF_T_MgrType_ParamType_Map_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
ALTER TABLE [dbo].[T_MgrType_ParamType_Map]  WITH CHECK ADD  CONSTRAINT [FK_T_MgrType_ParamType_Map_T_MgrTypes] FOREIGN KEY([MgrTypeID])
REFERENCES [dbo].[T_MgrTypes] ([MT_TypeID])
GO
ALTER TABLE [dbo].[T_MgrType_ParamType_Map] CHECK CONSTRAINT [FK_T_MgrType_ParamType_Map_T_MgrTypes]
GO
ALTER TABLE [dbo].[T_MgrType_ParamType_Map]  WITH CHECK ADD  CONSTRAINT [FK_T_MgrType_ParamType_Map_T_ParamType] FOREIGN KEY([ParamTypeID])
REFERENCES [dbo].[T_ParamType] ([ParamID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_MgrType_ParamType_Map] CHECK CONSTRAINT [FK_T_MgrType_ParamType_Map_T_ParamType]
GO
/****** Object:  Trigger [dbo].[trig_u_T_MgrType_ParamType_Map] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create TRIGGER [dbo].[trig_u_T_MgrType_ParamType_Map] ON [dbo].[T_MgrType_ParamType_Map] 
FOR UPDATE
AS
/****************************************************
**
**	Desc: 
**		Updates Last_Affected and Entered_By if the 
**		parameter value changes
**
**		Note that the SYSTEM_USER and suser_sname() functions are equivalent, with
**		 both returning the username in the form PNL\D3L243 if logged in using 
**		 integrated authentication or returning the Sql Server login name if
**		 logged in with a Sql Server login
**
**	Auth:	mem
**	Date:	04/11/2008
**    
*****************************************************/
	
	If @@RowCount = 0
		Return

	If	Update([MgrTypeID]) OR
		Update([ParamTypeID]) OR
		Update([DefaultValue])
	Begin
		UPDATE T_MgrType_ParamType_Map
		SET Last_Affected = GetDate(),
			Entered_By = SYSTEM_USER
		FROM T_MgrType_ParamType_Map
			 INNER JOIN inserted
			   ON T_MgrType_ParamType_Map.ParamTypeID = inserted.ParamTypeID AND
				  T_MgrType_ParamType_Map.MgrTypeID = inserted.MgrTypeID
	End


GO
