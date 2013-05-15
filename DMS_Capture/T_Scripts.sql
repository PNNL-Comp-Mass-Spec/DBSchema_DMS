/****** Object:  Table [dbo].[T_Scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Scripts](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Enabled] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Results_Tag] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Contents] [xml] NULL,
 CONSTRAINT [PK_T_Scripts] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Scripts] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Scripts] ON [dbo].[T_Scripts] 
(
	[Script] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_Scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER trig_d_Scripts ON dbo.T_Scripts 
FOR DELETE
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO dbo.T_Scripts_History
		(ID, Script, Results_Tag, Contents)
	SELECT ID, 'Deleted: ' + Script, Results_Tag, Contents
	FROM deleted
	ORDER BY deleted.ID

GO
/****** Object:  Trigger [dbo].[trig_i_Scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER trig_i_Scripts ON dbo.T_Scripts 
FOR INSERT
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	INSERT INTO dbo.T_Scripts_History
		(ID, Script, Results_Tag, Contents)
	SELECT ID, Script, Results_Tag, Contents
	FROM inserted
	ORDER BY inserted.ID

GO
/****** Object:  Trigger [dbo].[trig_u_Scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create TRIGGER trig_u_Scripts ON dbo.T_Scripts 
FOR UPDATE
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(Script) or Update(Results_Tag) Or Update(Contents)
	Begin
		INSERT INTO dbo.T_Scripts_History
			(ID, Script, Results_Tag, Contents)
		SELECT ID, Script, Results_Tag, Contents
		FROM inserted
		ORDER BY inserted.ID
	End

GO
ALTER TABLE [dbo].[T_Scripts] ADD  CONSTRAINT [DF_T_Scripts_Enabled]  DEFAULT ('N') FOR [Enabled]
GO
