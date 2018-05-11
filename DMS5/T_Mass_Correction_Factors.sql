/****** Object:  Table [dbo].[T_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Mass_Correction_Factors](
	[Mass_Correction_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Mass_Correction_Tag] [char](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Monoisotopic_Mass_Correction] [float] NOT NULL,
	[Average_Mass_Correction] [float] NULL,
	[Affected_Atom] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Original_Source] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Original_Source_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Alternative_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Empirical_Formula] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Mass_Correction_Factors] PRIMARY KEY NONCLUSTERED 
(
	[Mass_Correction_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY],
 CONSTRAINT [IX_T_Mass_Correction_Factors_MonoisotopicMass_and_AffectedAtom] UNIQUE CLUSTERED 
(
	[Monoisotopic_Mass_Correction] ASC,
	[Affected_Atom] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Mass_Correction_Factors] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Mass_Correction_Factors] TO [DMSMassCorrectionAdder] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Mass_Correction_Factors] TO [DMSMassCorrectionAdder] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Mass_Correction_Factors] TO [DMSMassCorrectionAdder] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Mass_Correction_Factors] TO [DMSMassCorrectionAdder] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Mass_Correction_Factors] TO [PNL\D3M578] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Mass_Correction_Factors] TO [PNL\D3M578] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Mass_Correction_Factors] TO [PNL\D3M578] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Mass_Correction_Factors] TO [PNL\D3M578] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Mass_Correction_Factors] TO [PNL\D3M578] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Mass_Correction_Factors_Mass_Correction_Tag] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Mass_Correction_Factors_Mass_Correction_Tag] ON [dbo].[T_Mass_Correction_Factors]
(
	[Mass_Correction_Tag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] ADD  CONSTRAINT [DF_T_Mass_Correction_Factors_Affected_Atom]  DEFAULT ('-') FOR [Affected_Atom]
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] ADD  CONSTRAINT [DF_T_Mass_Correction_Factors_Original_Source]  DEFAULT ('') FOR [Original_Source]
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] ADD  CONSTRAINT [DF_T_Mass_Correction_Factors_Original_Source_Name]  DEFAULT ('') FOR [Original_Source_Name]
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors]  WITH CHECK ADD  CONSTRAINT [CK_T_Mass_Correction_Factors_Tag] CHECK  ((NOT [Mass_Correction_Tag] like '%:%' AND NOT [Mass_Correction_Tag] like '%,%'))
GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] CHECK CONSTRAINT [CK_T_Mass_Correction_Factors_Tag]
GO
/****** Object:  Trigger [dbo].[trig_i_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger trig_i_Mass_Correction_Factors on dbo.T_Mass_Correction_Factors
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Mass_Correction_Factors_Change_History (
				Mass_Correction_ID, Mass_Correction_Tag, Description, 
			    Monoisotopic_Mass_Correction, Average_Mass_Correction, 
			    Affected_Atom, Original_Source, Original_Source_Name, 
				Monoisotopic_Mass_Change, Average_Mass_Change, 
				Entered, Entered_By)
	SELECT 	Mass_Correction_ID, Mass_Correction_Tag, Description, 
		    Monoisotopic_Mass_Correction, Average_Mass_Correction, 
		    Affected_Atom, Original_Source, Original_Source_Name, 
			0 AS Monoisotopic_Mass_Change, 0 AS Average_Mass_Change, 
			GetDate(), SYSTEM_USER
	FROM inserted

GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] ENABLE TRIGGER [trig_i_Mass_Correction_Factors]
GO
/****** Object:  Trigger [dbo].[trig_u_Mass_Correction_Factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger trig_u_Mass_Correction_Factors on dbo.T_Mass_Correction_Factors
For Update
AS
	If @@RowCount = 0
		Return

	if update(Mass_Correction_Tag) or 
	   update(Monoisotopic_Mass_Correction) or 
	   update(Average_Mass_Correction) or 
	   update(Affected_Atom)
		INSERT INTO T_Mass_Correction_Factors_Change_History (
					Mass_Correction_ID, Mass_Correction_Tag, Description, 
				    Monoisotopic_Mass_Correction, Average_Mass_Correction, 
				    Affected_Atom, Original_Source, Original_Source_Name, 
					Monoisotopic_Mass_Change, 
					Average_Mass_Change,
					Entered, Entered_By)
		SELECT 	inserted.Mass_Correction_ID, inserted.Mass_Correction_Tag, inserted.Description, 
			    inserted.Monoisotopic_Mass_Correction, inserted.Average_Mass_Correction, 
			    inserted.Affected_Atom, inserted.Original_Source, inserted.Original_Source_Name, 
				ROUND(inserted.Monoisotopic_Mass_Correction - deleted.Monoisotopic_Mass_Correction, 10),
				ROUND(inserted.Average_Mass_Correction - deleted.Average_Mass_Correction, 10),
				GetDate(), SYSTEM_USER
		FROM deleted INNER JOIN inserted ON deleted.Mass_Correction_ID = inserted.Mass_Correction_ID

GO
ALTER TABLE [dbo].[T_Mass_Correction_Factors] ENABLE TRIGGER [trig_u_Mass_Correction_Factors]
GO
