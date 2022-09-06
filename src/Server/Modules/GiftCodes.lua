-- Gift Codes
-- Username
-- September 7, 2019



local GiftCodes = {
    ["Gift"] = {
        ["WELCOME_BUNDLE"] = {
            Name = "Thanks for joining A:H!";
            Title = "This is a welcome bundle!";
            Id = "WELCOME_BUNDLE";
            Message = "Thanks for joining the A:H (pre):Season Beta! This bundle is pretty cool, and we thought you might like it. Enjoy. Oh, this should also boost you straight to Level 10!";
            Gifts = {
                Items = {"Stormbreaker"};
                EXP = 1190;
                Munny = 7200;
            };
            ExpireDate = 0
        };

        ["TESTER_GIFT"] = {
            Name = "Tester Boost";
            Title = "Thanks for testing!";
            Id = "TESTER_GIFT";
            Message = "Thanks for helping us test today. This is an instant boost to at least Level 10 through a flat award of EX.";
            Gifts = {
                Items = {};
                EXP = 1190;
            };
            ExpireDate = 0
        };

        ["OniiGift"] = {
            Name = "the onii gift";
            Title = "Thanks for testing!";
            Id = "OniiGift";
            Message = "Thanks for helping us test today. This is an instant boost to at least Level 10 through a flat award of EX.";
            Gifts = {
                Items = {};
                EXP = 4880;
            };
            ExpireDate = 0
        };

        ["CreditRefund"] = {
            Name = "Credit Refund";
            Title = "Sorry about that!";
            Id = "CreditRefund";
            Message = "Because of the bug regarding missing credits, we've decided to award everyone 1100 SayoCredits for free! If you purchased the 1350 bundle, let us know and we'll send an additional amount soon. Sorry for the inconvenience.";
            Gifts = {
                Items = {};
                SayoCredits = 1100;
            };
            ExpireDate = 0
        };

    };
    ["Available"] = {
        -- ["TESTER0917"] = "TESTER_GIFT"
    };
    ["OneTime"] = {
        
        --creator codes, re-enable later on
        ["THISISFORMEONL11"] = "OniiGift";
        ["THEONIIGIFT2"] = "OniiGift";
        ["thisNewCode"] = "OniiGift";

    };

    ["Single"] ={
        ["WESORRY02"] = "CreditRefund";
        
    }
}


return GiftCodes