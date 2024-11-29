-- ---------------------------------------------------------------------------
--
-- Theme: shortbread_v1
--
-- test-helper.lua
--
-- ---------------------------------------------------------------------------

require 'busted.runner'()

local helper = dofile('../helper.lua')

describe('test is_yes_true_or_one', function()

    it('should return true for yes, true, and 1', function()
        assert.is_true(helper.is_yes_true_or_one('yes'))
        assert.is_true(helper.is_yes_true_or_one('true'))
        assert.is_true(helper.is_yes_true_or_one('1'))
    end)

    it('should return false for anything else', function()
        assert.is_false(helper.is_yes_true_or_one())
        assert.is_false(helper.is_yes_true_or_one(nil))
        assert.is_false(helper.is_yes_true_or_one('no'))
        assert.is_false(helper.is_yes_true_or_one('false'))
        assert.is_false(helper.is_yes_true_or_one('0'))
        assert.is_false(helper.is_yes_true_or_one('abc'))
    end)

end)

-- ---------------------------------------------------------------------------
