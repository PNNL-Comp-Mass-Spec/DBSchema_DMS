/****** Object:  Table [dbo].[T_Charge_Code] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Charge_Code](
	[Charge_Code] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Resp_PRN] [varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Resp_HID] [varchar](7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[WBS_Title] [varchar](60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Charge_Code_Title] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SubAccount] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SubAccount_Title] [varchar](60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Setup_Date] [datetime] NOT NULL,
	[SubAccount_Effective_Date] [datetime] NULL,
	[Inactive_Date] [datetime] NULL,
	[SubAccount_Inactive_Date] [datetime] NULL,
	[Inactive_Date_Most_Recent] [datetime] NULL,
	[Deactivated] [varchar](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Auth_Amt] [numeric](12, 0) NOT NULL,
	[Auth_PRN] [varchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Auth_HID] [varchar](7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Auto_Defined] [tinyint] NOT NULL,
	[Charge_Code_State] [smallint] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
	[Usage_SamplePrep] [int] NULL,
	[Usage_RequestedRun] [int] NULL,
	[Activation_State] [tinyint] NOT NULL,
	[SortKey]  AS (case when [Activation_State]=(3) OR [Activation_State]=(0) then '0' else '1' end+(CONVERT([varchar](3),[Activation_State],(0))+[Charge_Code])) PERSISTED,
 CONSTRAINT [PK_T_Charge_Code] PRIMARY KEY CLUSTERED 
(
	[Charge_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Charge_Code_Resp_PRN] ******/
CREATE NONCLUSTERED INDEX [IX_T_Charge_Code_Resp_PRN] ON [dbo].[T_Charge_Code]
(
	[Resp_PRN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_Charge_Code_SortKey] ******/
CREATE NONCLUSTERED INDEX [IX_T_Charge_Code_SortKey] ON [dbo].[T_Charge_Code]
(
	[SortKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Charge_Code] ADD  CONSTRAINT [DF_T_Charge_Code_Deactivated]  DEFAULT ('N') FOR [Deactivated]
GO
ALTER TABLE [dbo].[T_Charge_Code] ADD  CONSTRAINT [DF_T_Charge_Code_Auto_Defined]  DEFAULT ((0)) FOR [Auto_Defined]
GO
ALTER TABLE [dbo].[T_Charge_Code] ADD  CONSTRAINT [DF_T_Charge_Code_Charge_Code_State]  DEFAULT ((1)) FOR [Charge_Code_State]
GO
ALTER TABLE [dbo].[T_Charge_Code] ADD  CONSTRAINT [DF_T_Charge_Code_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Charge_Code] ADD  CONSTRAINT [DF_T_Charge_Code_Activation_State]  DEFAULT ((0)) FOR [Activation_State]
GO
ALTER TABLE [dbo].[T_Charge_Code]  WITH CHECK ADD  CONSTRAINT [FK_T_Charge_Code_T_Charge_Code_Activation_State] FOREIGN KEY([Activation_State])
REFERENCES [dbo].[T_Charge_Code_Activation_State] ([Activation_State])
GO
ALTER TABLE [dbo].[T_Charge_Code] CHECK CONSTRAINT [FK_T_Charge_Code_T_Charge_Code_Activation_State]
GO
ALTER TABLE [dbo].[T_Charge_Code]  WITH CHECK ADD  CONSTRAINT [FK_T_Charge_Code_T_Charge_Code_State] FOREIGN KEY([Charge_Code_State])
REFERENCES [dbo].[T_Charge_Code_State] ([Charge_Code_State])
GO
ALTER TABLE [dbo].[T_Charge_Code] CHECK CONSTRAINT [FK_T_Charge_Code_T_Charge_Code_State]
GO
/****** Object:  Trigger [dbo].[trig_u_Charge_Code] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Charge_Code] on [dbo].[T_Charge_Code]
For Update
/****************************************************
**
**	Desc: 
**		Updates the Last_Affected and Activation_State columns
**
**	Auth:	mem
**	Date:	06/05/2013 mem - Initial Version
**			06/07/2013 mem - Now updating Activation_State

**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On
	
	If Update(Charge_Code_State)
	Begin		
		UPDATE T_Charge_Code
		SET Last_Affected = GetDate()
		FROM T_Charge_Code CC INNER JOIN
			 inserted ON CC.Charge_Code = inserted.Charge_Code

	End
	
	If Update(Deactivated) OR
	   Update(Charge_Code_State) OR
	   Update(Usage_SamplePrep) OR
	   Update(Usage_RequestedRun) OR
	   Update(Activation_State)
	Begin		
		UPDATE T_Charge_Code
		SET Activation_State = dbo.ChargeCodeActivationState(
		          inserted.Deactivated, 
		          inserted.Charge_Code_State, 
		          inserted.Usage_SamplePrep, 
		          inserted.Usage_RequestedRun)
		FROM T_Charge_Code CC
		     INNER JOIN inserted
		       ON CC.Charge_Code = inserted.Charge_Code

	End



GO
