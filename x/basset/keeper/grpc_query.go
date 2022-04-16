package keeper

import (
	"github.com/johnreitano/basset/x/basset/types"
)

var _ types.QueryServer = Keeper{}
