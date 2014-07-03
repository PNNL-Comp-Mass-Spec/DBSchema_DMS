/****** Object:  Table [dbo].[T_Residues_Change_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Residues_Change_History](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Residue_ID] [int] NOT NULL,
	[Residue_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Average_Mass] [float] NOT NULL,
	[Monoisotopic_Mass] [float] NOT NULL,
	[Num_C] [smallint] NOT NULL,
	[Num_H] [smallint] NOT NULL,
	[Num_N] [smallint] NOT NULL,
	[Num_O] [smallint] NOT NULL,
	[Num_S] [smallint] NOT NULL,
	[Monoisotopic_Mass_Change] [float] NULL,
	[Average_Mass_Change] [float] NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Residues_Change_History] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Residues_Change_History] ADD  CONSTRAINT [DF_T_Residues_Change_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Residues_Change_History] ADD  CONSTRAINT [DF_T_Residues_Change_History_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
