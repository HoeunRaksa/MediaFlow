import '../../../app_state.dart';
import '../../../core/constants/business_ids.dart';
import '../../materials/domain/product_sale_models.dart';
import '../domain/models/measurement_models.dart';
import '../domain/workspace_models.dart';

class MeasurementQuotationAdapter {
  const MeasurementQuotationAdapter();

  List<ProductSaleResult> createLines({
    required AppState state,
    required MeasurementCandidate candidate,
    required List<MeasurementProductVariant> variants,
  }) {
    final variantsById = {
      for (final variant in variants) variant.variantId: variant,
    };
    return [
      for (final quantity in candidate.quantities)
        if (quantity.purchaseQuantity > 0 &&
            variantsById[quantity.variantId] != null)
          state.calculateProductSale(
            ProductSaleInput(
              productKindId: 'ceiling_material_only',
              materialId:
                  variantsById[quantity.variantId]!.materialId ?? 'ceiling_6mm',
              inputMethodId: InputMethodIds.manualQuantity,
              chargeMethodId: ChargeMethodIds.unitOnly,
              manualQuantity: quantity.purchaseQuantity,
              saleUnitPrice:
                  variantsById[quantity.variantId]!.materialId == null
                  ? variantsById[quantity.variantId]!.unitPrice
                  : null,
              costUnitPrice:
                  variantsById[quantity.variantId]!.materialId == null
                  ? variantsById[quantity.variantId]!.unitPrice
                  : null,
              displaySpec: variantsById[quantity.variantId]!.label,
              useSavedPriceAsDefault: true,
              allowSaleBelowCost: state.allowSaleBelowCost,
            ),
          ),
    ];
  }

  List<ProductSaleResult> createAreaLines({
    required AppState state,
    required AreaCoverageCandidate candidate,
    required List<MeasurementProductVariant> variants,
  }) {
    final variant = variants
        .where((item) => item.variantId == candidate.variantId)
        .firstOrNull;
    if (variant == null || candidate.purchaseQuantity <= 0) {
      return const [];
    }
    return [
      state.calculateProductSale(
        ProductSaleInput(
          productKindId: 'ceiling_material_only',
          materialId: 'ceiling_6mm',
          inputMethodId: InputMethodIds.manualQuantity,
          chargeMethodId: ChargeMethodIds.unitOnly,
          manualQuantity: candidate.purchaseQuantity,
          saleUnitPrice: variant.unitPrice,
          costUnitPrice: variant.unitPrice,
          displaySpec: '${variant.label} • ប៉ាន់ស្មានតាម m²',
          useSavedPriceAsDefault: false,
          allowSaleBelowCost: state.allowSaleBelowCost,
        ),
      ),
    ];
  }

  List<ProductSaleResult> createWorkspaceLines({
    required AppState state,
    required WorkspaceCalculationResult result,
    Map<String, WorkspaceDesignOption> selectedDesigns = const {},
  }) {
    return [
      for (final material in result.materials)
        for (final line in material.lines)
          state.calculateProductSale(
            ProductSaleInput(
              productKindId: 'ceiling_material_only',
              materialId:
                  selectedDesigns[material.selection.product.id]?.materialId ??
                  line.variant.materialId,
              inputMethodId:
                  line.variant.priceTypeId == PriceTypeIds.saleBoxPrice
                  ? InputMethodIds.boxQuantity
                  : InputMethodIds.manualQuantity,
              chargeMethodId:
                  line.variant.priceTypeId == PriceTypeIds.saleBoxPrice
                  ? ChargeMethodIds.boxOnly
                  : ChargeMethodIds.unitOnly,
              boxQuantity: line.variant.priceTypeId == PriceTypeIds.saleBoxPrice
                  ? line.quantity
                  : null,
              manualQuantity:
                  line.variant.priceTypeId == PriceTypeIds.saleBoxPrice
                  ? null
                  : line.quantity,
              saleUnitPrice:
                  line.variant.priceTypeId == PriceTypeIds.saleUnitPrice
                  ? line.unitPrice
                  : null,
              saleBoxPrice:
                  line.variant.priceTypeId == PriceTypeIds.saleBoxPrice
                  ? line.unitPrice
                  : null,
              displaySpec:
                  selectedDesigns[material.selection.product.id] == null
                  ? line.variant.label
                  : '${line.variant.label} • ${selectedDesigns[material.selection.product.id]!.code}',
              useSavedPriceAsDefault: true,
              allowSaleBelowCost: state.allowSaleBelowCost,
            ),
          ),
    ];
  }
}
