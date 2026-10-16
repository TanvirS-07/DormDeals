import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

// Phones get a bottom sheet, anything wider gets a centered dialog.
void showListingEditor(BuildContext context, {Listing? existingListing}) {
  final isPhone = MediaQuery.sizeOf(context).width < 600;

  if (isPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => NewListing(existingListing: existingListing),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: NewListing(existingListing: existingListing),
      ),
    ),
  );
}

class NewListing extends StatefulWidget {
  const NewListing({super.key, this.existingListing});

  final Listing? existingListing;

  @override
  State<NewListing> createState() {
    return _NewListingState();
  }
}

class _NewListingState extends State<NewListing> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _pickupLocationController;
  late ItemCategory _chosenCategory;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  String? _validationError;

  bool get _isEditing => widget.existingListing != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final listing = widget.existingListing;

    _titleController = TextEditingController(text: listing?.title ?? '');
    _descriptionController = TextEditingController(
      text: listing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: listing == null ? '' : listing.price.toStringAsFixed(2),
    );
    _pickupLocationController = TextEditingController(
      text: listing?.pickupLocation ?? '',
    );
    _chosenCategory = listing?.category ?? ItemCategory.textbook;
    _latitude = listing?.latitude;
    _longitude = listing?.longitude;
  }

  void _pickImage() async {
    final imagePicker = ImagePicker();

    final selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 75,
    );

    if (selectedImage == null) {
      return;
    }

    final imageBytes = await selectedImage.readAsBytes();

    // Keep uploaded images small enough for fast listing display and small storage sizes.
    if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo is too large. Please choose an image under 5 MB.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedImage = selectedImage;
      _selectedImageBytes = imageBytes;
    });
  }

  void _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Request location only when the user chooses to attach their current pickup point.
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions were denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _saveListing() async {
    final itemPrice = double.tryParse(_priceController.text);

    final listing = Listing(
      id: widget.existingListing?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: itemPrice ?? 0.0,
      category: _chosenCategory,
      pickupLocation: _pickupLocationController.text.trim(),
      sellerId: widget.existingListing?.sellerId ?? '',
      sellerName: widget.existingListing?.sellerName ?? '',
      createdAt: widget.existingListing?.createdAt ?? DateTime.now(),
      image: widget.existingListing?.image,
      latitude: _latitude,
      longitude: _longitude,
    );

    final validationError = listing.validationError;

    setState(() {
      _validationError = validationError;
    });

    if (validationError != null) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save and create a listing.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final oldImageUrl = widget.existingListing?.image;
      String? imageUrl = oldImageUrl;
      String? newlyUploadedImageUrl;

      if (_selectedImage != null) {
        final imageBytes =
            _selectedImageBytes ?? await _selectedImage!.readAsBytes();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('listing_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putData(imageBytes);
        imageUrl = await storageRef.getDownloadURL();
        newlyUploadedImageUrl = imageUrl;
      }

      final listingWithImage = listing.copyWith(
        sellerId: widget.existingListing?.sellerId ?? currentUser.uid,
        sellerName:
            widget.existingListing?.sellerName ??
            currentUser.email ??
            'Student Seller',
        image: imageUrl,
      );

      if (widget.existingListing == null) {
        await Provider.of<ListingState>(
          context,
          listen: false,
        ).addListing(listingWithImage);
      } else {
        await Provider.of<ListingState>(
          context,
          listen: false,
        ).updateListing(listingWithImage);
      }

      // After Firestore points to the new photo, remove the old image file so they do not take up storage.
      if (widget.existingListing != null &&
          newlyUploadedImageUrl != null &&
          oldImageUrl != null &&
          oldImageUrl != newlyUploadedImageUrl) {
        await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving listing: $error')));
    }
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _photoPicker() {
    final existingImage = widget.existingListing?.image;
    final hasPhoto = _selectedImageBytes != null || existingImage != null;

    Widget preview;
    if (_selectedImageBytes != null) {
      preview = Image.memory(_selectedImageBytes!, fit: BoxFit.cover);
    } else if (existingImage != null) {
      preview = Image.network(
        existingImage,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      );
    } else {
      preview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairline),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add Photo',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          const Text(
            'Optional, JPG or PNG under 5 MB',
            style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
          ),
        ],
      );
    }

    return Material(
      color: AppColors.sunken,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isSaving ? null : _pickImage,
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              if (hasPhoto)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedImageBytes != null
                          ? 'Photo selected, tap to change'
                          : 'Photo already uploaded, tap to change',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationButton() {
    final hasLocation = _latitude != null && _longitude != null;

    if (hasLocation && !_isGettingLocation) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Location attached, buyers can open it in Maps',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentPressed,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _latitude = null;
                  _longitude = null;
                });
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _isGettingLocation ? null : _getCurrentLocation,
        icon: _isGettingLocation
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location, size: 18),
        label: const Text('Use Current Location'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit listing' : 'Sell something',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditing
                        ? 'Changes show up on the board straight away.'
                        : 'Students on campus will see this on the board.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _photoPicker(),
                  const SizedBox(height: 20),
                  _fieldLabel('Title'),
                  TextField(
                    controller: _titleController,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g. COMP3130 notes, weeks 1-13',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _fieldLabel('Description'),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Condition, edition, what\'s included...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _fieldLabel('Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in ItemCategory.values)
                        ChoiceChip(
                          selected: _chosenCategory == category,
                          onSelected: (_) {
                            setState(() {
                              _chosenCategory = category;
                            });
                          },
                          avatar: Icon(
                            categoryIcons[category],
                            size: 16,
                            color: _chosenCategory == category
                                ? Colors.white
                                : AppColors.inkMuted,
                          ),
                          label: Text(category.label),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Price'),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        hintText: '0.00',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Pickup location'),
                  TextField(
                    controller: _pickupLocationController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Library foyer, level 2',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _locationButton(),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _validationError == null
                ? const SizedBox(width: double.infinity)
                : Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.inkMuted,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveListing,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Create Listing'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
