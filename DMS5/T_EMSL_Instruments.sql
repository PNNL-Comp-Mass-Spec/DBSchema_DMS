/****** Object:  Table [dbo].[T_EMSL_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instruments](
	[EUS_Display_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Instrument_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Instrument_ID] [int] NOT NULL,
	[EUS_Available_Hours] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Local_Category_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Local_Instrument_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL,
	[EUS_Active_Sw] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Primary_Instrument] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_EMSL_Instruments] PRIMARY KEY CLUSTERED 
(
	[EUS_Instrument_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_EMSL_Instruments] ADD  CONSTRAINT [DF_T_EMSL_Instruments_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
