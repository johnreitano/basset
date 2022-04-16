package keeper_test

import (
	"testing"

	testkeeper "github.com/johnreitano/basset/testutil/keeper"
	"github.com/johnreitano/basset/x/basset/types"
	"github.com/stretchr/testify/require"
)

func TestGetParams(t *testing.T) {
	k, ctx := testkeeper.BassetKeeper(t)
	params := types.DefaultParams()

	k.SetParams(ctx, params)

	require.EqualValues(t, params, k.GetParams(ctx))
}
