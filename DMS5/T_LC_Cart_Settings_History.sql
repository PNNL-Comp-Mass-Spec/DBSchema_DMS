/****** Object:  Table [dbo].[T_LC_Cart_Settings_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Settings_History](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Cart_ID] [int] NOT NULL,
	[Valve_To_Column_Extension] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Operating_Pressure] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Interface_Configuration] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Valve_To_Column_Extension_Dimensions] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mixer_Volume] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Loop_Volume] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Loading_Time] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Split_Flow_Rate] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Split_Column_Dimensions] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purge_Flow_Rate] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purge_Column_Dimensions] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Purge_Volume] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Acquisition_Time] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Solvent_A] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Solvent_B] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Date_Of_Change] [datetime] NULL,
	[Entered] [datetime] NOT NULL,
	[EnteredBy] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_LC_Cart_Settings] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_LC_Cart_Settings_History] ADD  CONSTRAINT [DF_T_LC_Cart_Settings_Created]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_LC_Cart_Settings_History]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Settings_History_T_LC_Cart] FOREIGN KEY([Cart_ID])
REFERENCES [dbo].[T_LC_Cart] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Settings_History] CHECK CONSTRAINT [FK_T_LC_Cart_Settings_History_T_LC_Cart]
GO
