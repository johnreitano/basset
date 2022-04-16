package basset_test

import (
	"testing"

	keepertest "github.com/johnreitano/basset/testutil/keeper"
	"github.com/johnreitano/basset/testutil/nullify"
	"github.com/johnreitano/basset/x/basset"
	"github.com/johnreitano/basset/x/basset/types"
	"github.com/stretchr/testify/require"
)

func TestGenesis(t *testing.T) {
	genesisState := types.GenesisState{
		Params: types.DefaultParams(),

		// this line is used by starport scaffolding # genesis/test/state
	}

	k, ctx := keepertest.BassetKeeper(t)
	basset.InitGenesis(ctx, *k, genesisState)
	got := basset.ExportGenesis(ctx, *k)
	require.NotNil(t, got)

	nullify.Fill(&genesisState)
	nullify.Fill(got)

	// this line is used by starport scaffolding # genesis/test/assert
}
