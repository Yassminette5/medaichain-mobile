import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/user_info_view_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/height_roller_painter.dart';

/// ----------------------
/// Height Screen (Step 3 of 5)
/// ----------------------
class HeightStepScreen extends StatefulWidget {
  final VoidCallback onNextClicked;

  const HeightStepScreen({super.key, required this.onNextClicked});

  @override
  State<HeightStepScreen> createState() => _HeightStepScreenState();
}

class _HeightStepScreenState extends State<HeightStepScreen> {
  late ScrollController _scrollController;
  final double _itemWidth = 12.0;
  final int _minHeight = 120;
  final int _maxHeight = 220;
  final Color _brandColor = AppColors.primary;
  final Color _accentColor = AppColors.secondary;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    _scrollController = ScrollController(
      initialScrollOffset: (viewModel.currentHeight - _minHeight) * _itemWidth,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final viewModel = Provider.of<UserInfoViewModel>(context, listen: false);
    final int newHeight = _minHeight + (_scrollController.offset / _itemWidth).round();
    if (newHeight >= _minHeight && newHeight <= _maxHeight && newHeight != viewModel.currentHeight) {
      viewModel.setCurrentHeight(newHeight);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<UserInfoViewModel>(context);
    int currentHeight = viewModel.currentHeight;

    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: "How "),
              TextSpan(
                text: "tall ",
                style: TextStyle(color: _accentColor),
              ),
              const TextSpan(text: "are you?"),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "We will use this data to give you a better diet type for you.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Heart Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _brandColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.favorite, color: _brandColor, size: 24),
        ),
        Icon(Icons.keyboard_arrow_down, color: _brandColor, size: 24),

        const SizedBox(height: 20),

        // Height Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeightBox(currentHeight - 1, isSelected: false),
            const SizedBox(width: 15),
            _buildHeightBox(currentHeight, isSelected: true),
            const SizedBox(width: 15),
            _buildHeightBox(currentHeight + 1, isSelected: false),
          ],
        ),

        const SizedBox(height: 40),

        // Roller/Ruler
        Container(
          height: 100,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The Ruler
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification) {
                    _snapToValue();
                  }
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: 1, // We use a CustomPaint inside
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: (_maxHeight - _minHeight) * _itemWidth + MediaQuery.of(context).size.width,
                      child: CustomPaint(
                        painter: RulerPainter(
                          min: _minHeight,
                          max: _maxHeight,
                          scrollOffset: _scrollController.hasClients ? _scrollController.offset : (_minHeight - _minHeight) * _itemWidth,
                          itemWidth: _itemWidth,
                          color: Colors.white30,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Gradient Overlay for Ruler
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.darkBackground,
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.darkBackground,
                        ],
                        stops: const [0.0, 0.2, 0.8, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),

              // Teal Indicator Line
              Positioned(
                bottom: 65,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _brandColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                bottom: 65,
                left: MediaQuery.of(context).size.width * 0.1,
                child: Container(
                  width: ((currentHeight - _minHeight) / (_maxHeight - _minHeight)) * (MediaQuery.of(context).size.width * 0.8),
                  height: 3,
                  decoration: BoxDecoration(
                    color: _brandColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Center Indicator Dot
              Positioned(
                bottom: 58,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Next Button (Standardized with Gender Screen)
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4), 
                  blurRadius: 20, 
                  spreadRadius: 5
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onNextClicked,
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeightBox(int value, {required bool isSelected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: isSelected ? 110 : 90,
      height: isSelected ? 180 : 150,
      decoration: BoxDecoration(
        color: isSelected ? _brandColor : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "$value ",
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white38,
              ),
            ),
            TextSpan(
              text: "cm",
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 20 : 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snapToValue() {
    final double offset = _scrollController.offset;
    final double target = (offset / _itemWidth).round() * _itemWidth;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

