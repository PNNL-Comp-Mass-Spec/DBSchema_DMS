/****** Object:  Table [dbo].[T_Instrument_Allocation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Allocation](
	[Allocation_Tag] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Fiscal_Year] [int] NOT NULL,
	[Allocated_Hours] [float] NULL,
	[Comment] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[Last_Affected] [datetime] NULL,
	[FY_Proposal]  AS ((CONVERT([varchar](4),[Fiscal_Year],(0))+'_')+[Proposal_ID]) PERSISTED,
 CONSTRAINT [PK_T_Instrument_Allocation] PRIMARY KEY CLUSTERED 
(
	[Allocation_Tag] ASC,
	[Proposal_ID] ASC,
	[Fiscal_Year] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Allocation] ADD  CONSTRAINT [DF_T_Instrument_Allocation_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Instrument_Allocation] ADD  CONSTRAINT [DF_T_Instrument_Allocation_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Instrument_Allocation] ADD  CONSTRAINT [DF_T_Instrument_Allocation_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
/****** Object:  Trigger [dbo].[trig_d_Instrument_Allocation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_d_Instrument_Allocation] on [dbo].[T_Instrument_Allocation]
For Delete
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Instrument_Allocation_Updates for the deleted allocation entries
**
**	Auth:	mem
**	Date:	03/30/2012 mem - Initial version
**    
*****************************************************/
AS
	Set NoCount On

	-- Add entries to T_Instrument_Allocation_Updates for each deleted row
	INSERT INTO dbo.T_Instrument_Allocation_Updates( Allocation_Tag,
	                                                 Proposal_ID,
	                                                 Fiscal_Year,
	                                                 Allocated_Hours_Old,
	                                                 Allocated_Hours_New,
	                                                 Comment,
	                                                 Entered)
	SELECT Allocation_Tag,
	       Proposal_ID,
	       Fiscal_Year,
	       Allocated_Hours AS Allocated_Hours_Old,
	       Null AS Allocated_Hours_New,
	       Case When ISNULL(Comment, '') = '' Then '(deleted)'
	       Else '(deleted); ' + Comment
	       End AS Comment,
	       GetDate()	       
	FROM deleted
	ORDER BY Allocation_Tag, Proposal_ID

GO
/****** Object:  Trigger [dbo].[trig_i_Instrument_Allocation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_i_Instrument_Allocation] on [dbo].[T_Instrument_Allocation]
For Insert
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Instrument_Allocation_Updates for the new allocation entries
**
**	Auth:	mem
**	Date:	03/30/2012 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO dbo.T_Instrument_Allocation_Updates( Allocation_Tag,
	                                                 Proposal_ID,
	                                                 Fiscal_Year,
	                                                 Allocated_Hours_Old,
	                                                 Allocated_Hours_New,
	                                                 Comment,
	                                                 Entered)
	SELECT Allocation_Tag,
	       Proposal_ID,
	       Fiscal_Year,
	       NULL AS Allocated_Hours_Old,
	       Allocated_Hours AS Allocated_Hours_New,
	       '' AS Comment,
	       GetDate()
	FROM inserted
	ORDER BY inserted.Allocation_Tag, inserted.Proposal_ID

GO
/****** Object:  Trigger [dbo].[trig_u_Instrument_Allocation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_Instrument_Allocation] on [dbo].[T_Instrument_Allocation]
For Update
/****************************************************
**
**	Desc: 
**		Makes an entry in T_Instrument_Allocation_Updates for each updated allocation entry
**		Renames entries in T_File_Attachment
**
**	Auth:	mem
**	Date:	03/31/2012 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Allocated_Hours) Or Update(Comment)
	Begin
		INSERT INTO dbo.T_Instrument_Allocation_Updates( Allocation_Tag,
														 Proposal_ID,
														 Fiscal_Year,
														 Allocated_Hours_Old,
														 Allocated_Hours_New,
														 Comment,
														 Entered )
		SELECT inserted.Allocation_Tag,
			   inserted.Proposal_ID,
			   inserted.Fiscal_Year,
			   deleted.Allocated_Hours AS Allocated_Hours_Old,
			   inserted.Allocated_Hours AS Allocated_Hours_New,
			   ISNULL(inserted.Comment, '') AS Comment,
			   GetDate()
		FROM deleted
			 INNER JOIN inserted
			   ON deleted.Allocation_Tag = inserted.Allocation_Tag AND
				  deleted.Proposal_ID = inserted.Proposal_ID
		WHERE ISNULL(deleted.Allocated_Hours, -1) <> ISNULL(inserted.Allocated_Hours, -1) OR
		      ISNULL(deleted.Comment, '') <> ISNULL(inserted.Comment, '')
		ORDER BY inserted.Allocation_Tag, inserted.Proposal_ID
	End

GO
