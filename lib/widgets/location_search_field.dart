import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;
  final bool enabled;
  final VoidCallback? onLocationSelected;

  const LocationSearchField({
    Key? key,
    required this.controller,
    this.validator,
    this.labelText = 'Ubicación',
    this.hintText = 'Buscar ciudad y departamento...',
    this.enabled = true,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<LocationData> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Agregar un pequeño delay antes de remover el overlay
      // para permitir que el onTap se ejecute
      Future.delayed(const Duration(milliseconds: 150), () {
        _removeOverlay();
      });
    }
  }

  void _onTextChanged(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
      _searchResults = LocationService.searchCities(value);
    });
    _updateOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _removeOverlay();
    if (_focusNode.hasFocus && _searchResults.isNotEmpty) {
      _showOverlay();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _searchResults.isEmpty
                  ? _buildNoResultsWidget()
                  : _buildResultsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _searchResults.length > 10 ? 10 : _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              print('Seleccionando ubicación: ${location.fullName}');
              _selectLocation(location);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: index < _searchResults.length - 1
                    ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.city,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          location.department,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectLocation(LocationData location) {
    print('_selectLocation llamado con: ${location.fullName}');
    widget.controller.text = location.fullName;
    setState(() {
      _searchResults.clear();
      _isSearching = false;
    });
    _focusNode.unfocus();
    _removeOverlay();
    widget.onLocationSelected?.call();
    print('Ubicación seleccionada y establecida: ${widget.controller.text}');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        onChanged: _onTextChanged,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {
                      _isSearching = false;
                      _searchResults.clear();
                    });
                    _removeOverlay();
                  },
                )
              : const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: widget.validator,
      ),
    );
  }
}