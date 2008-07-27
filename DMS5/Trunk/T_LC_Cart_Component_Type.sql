/****** Object:  Table [dbo].[T_LC_Cart_Component_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Component_Type](
	[ID] [int] IDENTITY(21,1) NOT NULL,
	[Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_LC_Cart_Component_Type_Description]  DEFAULT ('??'),
	[Traceable_By_Serial_Number] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_LC_Cart_Component_Type_Has_Serial_Number]  DEFAULT ('Y'),
 CONSTRAINT [PK_T_LC_Component_Type] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
