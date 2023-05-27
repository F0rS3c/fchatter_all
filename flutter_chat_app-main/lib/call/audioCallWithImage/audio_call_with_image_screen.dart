import '../size_config.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../size_config.dart';

class AudioCallWithImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body:Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.asset(
            "assets/images/bg.jpg",
            fit: BoxFit.cover,
          ),
          // Black Layer
          DecoratedBox(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Jemmy \nWilliams",
                    style: Theme.of(context)
                        .textTheme
                        .headline3
                        ?.copyWith(color: Colors.white),
                  ),
                  VerticalSpacing(of: 10),

                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [


                      SizedBox(
                        height: getProportionateScreenWidth(64),
                        width: getProportionateScreenWidth(64),
                        child: TextButton(
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(
                              EdgeInsets.all(15 / 64 * 64),
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(100)),
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all(kRedColor),
                          ),
                          onPressed: () {},
                          //icon flutter
                          child: Icon(
                            Icons.call_end,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
