/****** Object:  Table [dbo].[T_Residues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Residues](
	[Residue_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Residue_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Average_Mass] [float] NOT NULL,
	[Monoisotopic_Mass] [float] NOT NULL,
	[Num_C] [smallint] NOT NULL,
	[Num_H] [smallint] NOT NULL,
	[Num_N] [smallint] NOT NULL,
	[Num_O] [smallint] NOT NULL,
	[Num_S] [smallint] NOT NULL,
	[Empirical_Formula] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Residues] PRIMARY KEY NONCLUSTERED 
(
	[Residue_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Residues] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Residues_Symbol] ******/
CREATE CLUSTERED INDEX [IX_T_Residues_Symbol] ON [dbo].[T_Residues]
(
	[Residue_Symbol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_i_Residues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger trig_i_Residues on dbo.T_Residues
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Residues_Change_History (
				Residue_ID, Residue_Symbol, Description, Average_Mass, 
				Monoisotopic_Mass, Num_C, Num_H, Num_N, Num_O, Num_S, 
				Monoisotopic_Mass_Change, Average_Mass_Change, 
				Entered, Entered_By)
	SELECT 	Residue_ID, Residue_Symbol, Description, Average_Mass, 
			Monoisotopic_Mass, Num_C, Num_H, Num_N, Num_O, Num_S, 
			0 AS Monoisotopic_Mass_Change, 0 AS Average_Mass_Change, 
			GetDate(), SYSTEM_USER
	FROM inserted


GO
/****** Object:  Trigger [dbo].[trig_u_Residues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger trig_u_Residues on dbo.T_Residues
For Update
AS
	If @@RowCount = 0
		Return

	if update(Residue_Symbol) or 
	   update(Average_Mass) or 
	   update(Monoisotopic_Mass) or 
	   update(Num_C) or
	   update(Num_H) or
	   update(Num_N) or
	   update(Num_O) or
	   update(Num_S)
		INSERT INTO T_Residues_Change_History (
					Residue_ID, Residue_Symbol, Description, Average_Mass, 
					Monoisotopic_Mass, Num_C, Num_H, Num_N, Num_O, Num_S, 
					Monoisotopic_Mass_Change, 
					Average_Mass_Change, 
					Entered, Entered_By)
		SELECT 	inserted.Residue_ID, inserted.Residue_Symbol, inserted.Description, inserted.Average_Mass, 
				inserted.Monoisotopic_Mass, inserted.Num_C, inserted.Num_H, inserted.Num_N, inserted.Num_O, inserted.Num_S, 
				ROUND(inserted.Monoisotopic_Mass - deleted.Monoisotopic_Mass, 10),
				ROUND(inserted.Average_Mass - deleted.Average_Mass, 10),
				GetDate(), SYSTEM_USER
		FROM deleted INNER JOIN inserted ON deleted.Residue_ID = inserted.Residue_ID


GO
